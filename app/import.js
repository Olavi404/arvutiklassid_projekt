/**
 * @file        import.js
 * @description Impordib lähteandmed kolmest formaadist andmebaasi ühe tehinguna:
 *                classes.csv     -> classroom
 *                teachers.json   -> user_or_group
 *                bookings.xml    -> booking (+ lesson_type + booking_participant)
 * @author      Olavi Keerd (TAK25)
 * @created     2026-07-09
 * @modified    2026-07-09
 *
 * Käivitamine: DB_USER=app_user DB_PASS=app_pass_123 node import.js
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { XMLParser } from 'fast-xml-parser';
import { pool } from './db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const IMPORT_DIR = path.resolve(__dirname, '..', 'import');

/**
 * Lihtne CSV parser (koma-eraldusega, ilma jutumärkideta väljadeta).
 * @param {string} text CSV-faili sisu, esimene rida on päis
 * @returns {Object<string, string>[]} read objektidena, võtmeteks päise veerunimed
 */
function parseCSV(text) {
  const lines = text.trim().split(/\r?\n/);
  const headers = lines[0].split(',').map(h => h.trim());
  return lines.slice(1).map(line => {
    const cells = line.split(',');
    const row = {};
    headers.forEach((h, i) => { row[h] = (cells[i] ?? '').trim(); });
    return row;
  });
}

/**
 * Impordib klassid failist import/classes.csv. Olemasolev klass (sama nimi) uuendatakse.
 * @param {import('mysql2/promise').PoolConnection} conn avatud tehinguga ühendus
 */
async function importClasses(conn) {
  const csv = fs.readFileSync(path.join(IMPORT_DIR, 'classes.csv'), 'utf-8');
  const rows = parseCSV(csv);
  for (const r of rows) {
    await conn.query(
      `INSERT INTO classroom (name, location, capacity, computers_count)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE location=VALUES(location),
         capacity=VALUES(capacity), computers_count=VALUES(computers_count)`,
      [r.name, r.location, Number(r.capacity), Number(r.computers_count)]
    );
  }
  console.log(`  classroom: ${rows.length} rida imporditud`);
}

/**
 * Impordib õpetajad ja grupid failist import/teachers.json. Olemasolev (sama e-mail) uuendatakse.
 * @param {import('mysql2/promise').PoolConnection} conn avatud tehinguga ühendus
 */
async function importUsers(conn) {
  const json = JSON.parse(fs.readFileSync(path.join(IMPORT_DIR, 'teachers.json'), 'utf-8'));
  for (const u of json.users) {
    await conn.query(
      `INSERT INTO user_or_group (name, type, email)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE name=VALUES(name), type=VALUES(type)`,
      [u.name, u.type, u.email]
    );
  }
  console.log(`  user_or_group: ${json.users.length} rida imporditud`);
}

/**
 * Leiab tunnitüübi nime järgi või loob selle, kui seda veel pole.
 * @param {import('mysql2/promise').PoolConnection} conn
 * @param {string} name tunnitüübi nimi (nt "loeng")
 * @returns {Promise<number>} tunnitüübi id
 */
async function getLessonTypeId(conn, name) {
  const [rows] = await conn.query('SELECT id FROM lesson_type WHERE name = ?', [name]);
  if (rows.length) return rows[0].id;
  const [res] = await conn.query('INSERT INTO lesson_type (name) VALUES (?)', [name]);
  return res.insertId;
}

/**
 * Leiab rea id nime järgi.
 * NB: `table` lisatakse SQL-i otse, seega kutsu ainult koodis kirjutatud tabelinimega,
 * mitte kasutaja sisendiga.
 * @param {import('mysql2/promise').PoolConnection} conn
 * @param {'classroom'|'user_or_group'} table tabeli nimi
 * @param {string} name otsitav nimi
 * @returns {Promise<number|null>} id või null, kui ei leitud
 */
async function getIdByName(conn, table, name) {
  const [rows] = await conn.query(`SELECT id FROM ${table} WHERE name = ?`, [name]);
  return rows.length ? rows[0].id : null;
}

/**
 * Impordib broneeringud ja nende lisaosalejad failist import/bookings.xml.
 * Broneering jäetakse hoiatusega vahele, kui klassi või korraldajat ei leita.
 * @param {import('mysql2/promise').PoolConnection} conn avatud tehinguga ühendus
 */
async function importBookings(conn) {
  const xml = fs.readFileSync(path.join(IMPORT_DIR, 'bookings.xml'), 'utf-8');
  const parser = new XMLParser({ ignoreAttributes: false, isArray: (n) => n === 'booking' || n === 'participant' });
  const data = parser.parse(xml);
  const bookings = data.bookings.booking;

  let count = 0;
  for (const b of bookings) {
    const classroomId = await getIdByName(conn, 'classroom', b.classroom);
    const organizerId = await getIdByName(conn, 'user_or_group', b.organizer);
    const lessonTypeId = await getLessonTypeId(conn, b.lesson_type);

    if (!classroomId || !organizerId) {
      console.warn(`  HOIATUS: vahele jäetud (klass=${b.classroom}, korraldaja=${b.organizer})`);
      continue;
    }

    // XML-is on aeg kujul "HH:MM", TIME veerg ootab "HH:MM:SS"
    const start = String(b.start).length === 5 ? b.start + ':00' : b.start;
    const end = String(b.end).length === 5 ? b.end + ':00' : b.end;

    const [res] = await conn.query(
      `INSERT INTO booking
         (classroom_id, organizer_id, lesson_type_id, booking_date,
          start_time, end_time, participants_count, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [classroomId, organizerId, lessonTypeId, b.date, start, end,
       Number(b.participants), b.status || 'planned']
    );
    const bookingId = res.insertId;

    // Lisaosalejad (N..M vahetabelisse)
    if (b.extra_participants && b.extra_participants.participant) {
      for (const pName of b.extra_participants.participant) {
        const pid = await getIdByName(conn, 'user_or_group', pName);
        if (pid) {
          await conn.query(
            `INSERT IGNORE INTO booking_participant (booking_id, participant_id)
             VALUES (?, ?)`,
            [bookingId, pid]
          );
        }
      }
    }
    count++;
  }
  console.log(`  booking: ${count} rida imporditud`);
}

/**
 * Käivitab kogu impordi ühes tehingus: vea korral keeratakse kõik muudatused tagasi,
 * et andmebaas ei jääks poolikusse olekusse.
 */
async function main() {
  const conn = await pool.getConnection();
  try {
    console.log('Impordin andmed...');
    await conn.beginTransaction();
    await importClasses(conn);
    await importUsers(conn);
    await importBookings(conn);
    await conn.commit();
    console.log('Import õnnestus.');
  } catch (err) {
    await conn.rollback();
    console.error('Import ebaõnnestus, tehing tagasi keeratud:', err.message);
    process.exitCode = 1;
  } finally {
    conn.release();
    await pool.end();
  }
}

main();
