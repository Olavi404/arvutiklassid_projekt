/**
 * @file        server.js
 * @description Express REST API arvutiklasside broneeringute haldamiseks
 *              (CRUD + statistika) ja staatilise frontendi serveerimine.
 * @author      Olavi Keerd (TAK25)
 * @created     2026-07-09
 * @modified    2026-10-16
 *
 * Käivitamine: DB_USER=app_user DB_PASS=app_pass_123 PORT=3000 node server.js
 * Algoritmi kirjeldus: ../algoritm.md
 */
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from './db.js';
import { validateTimeRange, validateParticipants } from './validation.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

/**
 * Kontrollib, kas klassil on samal kuupäeval ajaliselt kattuv broneering (ärireegel 4).
 * Kaks vahemikku kattuvad, kui olemasolev.algus < uus.lõpp JA olemasolev.lõpp > uus.algus
 * (põhjendus: ../algoritm.md, punkt 3). Tühistatud broneeringuid ei arvestata.
 * @param {number|string} classroomId klassi id
 * @param {string} date kuupäev "YYYY-MM-DD"
 * @param {string} start uue broneeringu algus "HH:MM"
 * @param {string} end uue broneeringu lõpp "HH:MM"
 * @param {number|string|null} [excludeId] muudetava broneeringu id, et see ei kattuks iseendaga
 * @returns {Promise<boolean>} true, kui leidub kattuv broneering
 */
async function checkOverlap(classroomId, date, start, end, excludeId = null) {
  // Parameetrite järjekord vastab SQL-is: start_time < uus lõpp, end_time > uus algus
  const params = [classroomId, date, end, start];
  let sql = `SELECT id FROM booking
             WHERE classroom_id = ? AND booking_date = ?
               AND status <> 'cancelled'
               AND start_time < ? AND end_time > ?`;
  if (excludeId) { sql += ' AND id <> ?'; params.push(excludeId); }
  const [rows] = await pool.query(sql, params);
  return rows.length > 0;
}

// ============ LOOKUP-ANDMED (vormide jaoks) ============
/**
 * GET /api/lookups — klassid, kasutajad ja tunnitüübid vormi rippmenüüde jaoks.
 * Vastus: 200 { classrooms, users, types } | 500 { error }
 */
app.get('/api/lookups', async (req, res) => {
  try {
    const [classrooms] = await pool.query('SELECT id, name, capacity FROM classroom ORDER BY name');
    const [users] = await pool.query('SELECT id, name, type FROM user_or_group ORDER BY name');
    const [types] = await pool.query('SELECT id, name FROM lesson_type ORDER BY name');
    res.json({ classrooms, users, types });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ============ READ: kõik broneeringud (list) ============
/**
 * GET /api/bookings — kõik broneeringud koos klassi, korraldaja ja tunnitüübi nimega,
 * uuemad eespool. Vastus: 200 [ broneering ] | 500 { error }
 */
app.get('/api/bookings', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT b.id, b.booking_date, b.start_time, b.end_time,
             b.participants_count, b.status,
             c.name AS classroom, c.id AS classroom_id,
             u.name AS organizer, u.id AS organizer_id,
             lt.name AS lesson_type, lt.id AS lesson_type_id
      FROM booking b
      JOIN classroom c ON c.id = b.classroom_id
      JOIN user_or_group u ON u.id = b.organizer_id
      JOIN lesson_type lt ON lt.id = b.lesson_type_id
      ORDER BY b.booking_date DESC, b.start_time`);
    res.json(rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ============ CREATE: uus broneering ============
/**
 * POST /api/bookings — loob uue broneeringu pärast ärireeglite 1, 2 ja 4 kontrolli
 * (reegel 3 ehk mahtuvus kontrollitakse DB triggeris).
 * Vastus: 201 { id } | 400 vale aeg/osalejad | 409 ajaline kattumine | 500 { error }
 */
app.post('/api/bookings', async (req, res) => {
  try {
    const { classroom_id, organizer_id, lesson_type_id, booking_date,
            start_time, end_time, participants_count, status } = req.body;

    const timeError = validateTimeRange(start_time, end_time);
    if (timeError) return res.status(400).json({ error: timeError });
    const participantsError = validateParticipants(participants_count);
    if (participantsError) return res.status(400).json({ error: participantsError });
    if (await checkOverlap(classroom_id, booking_date, start_time, end_time))
      return res.status(409).json({ error: 'See klass on sel ajal juba broneeritud (ajaline kattumine)' });

    const [r] = await pool.query(
      `INSERT INTO booking (classroom_id, organizer_id, lesson_type_id,
         booking_date, start_time, end_time, participants_count, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [classroom_id, organizer_id, lesson_type_id, booking_date,
       start_time, end_time, participants_count, status || 'planned']);
    res.status(201).json({ id: r.insertId });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ============ UPDATE: muuda broneeringut ============
/**
 * PUT /api/bookings/:id — muudab olemasolevat broneeringut samade kontrollidega nagu POST.
 * Vastus: 200 { ok } | 400 | 404 ei leitud | 409 ajaline kattumine | 500 { error }
 */
app.put('/api/bookings/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { classroom_id, organizer_id, lesson_type_id, booking_date,
            start_time, end_time, participants_count, status } = req.body;

    const timeError = validateTimeRange(start_time, end_time);
    if (timeError) return res.status(400).json({ error: timeError });
    const participantsError = validateParticipants(participants_count);
    if (participantsError) return res.status(400).json({ error: participantsError });
    if (await checkOverlap(classroom_id, booking_date, start_time, end_time, id))
      return res.status(409).json({ error: 'See klass on sel ajal juba broneeritud (ajaline kattumine)' });

    const [r] = await pool.query(
      `UPDATE booking SET classroom_id=?, organizer_id=?, lesson_type_id=?,
         booking_date=?, start_time=?, end_time=?, participants_count=?, status=?
       WHERE id=?`,
      [classroom_id, organizer_id, lesson_type_id, booking_date,
       start_time, end_time, participants_count, status, id]);
    if (r.affectedRows === 0) return res.status(404).json({ error: 'Broneeringut ei leitud' });
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ============ DELETE: kustuta broneering ============
/**
 * DELETE /api/bookings/:id — kustutab broneeringu; lisaosalejad kustuvad
 * kaasa (ON DELETE CASCADE). Vastus: 200 { ok } | 404 ei leitud | 500 { error }
 */
app.delete('/api/bookings/:id', async (req, res) => {
  try {
    const [r] = await pool.query('DELETE FROM booking WHERE id=?', [req.params.id]);
    if (r.affectedRows === 0) return res.status(404).json({ error: 'Broneeringut ei leitud' });
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ============ STATISTIKA: klasside kasutus tundides nädalas ============
/**
 * GET /api/stats/weekly — klasside kasutus ISO-nädala kaupa (vaade v_weekly_classroom_usage).
 * Vastus: 200 [ { classroom_name, year_week, bookings_count, hours_used } ] | 500 { error }
 */
app.get('/api/stats/weekly', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT classroom_name, year_week, bookings_count, hours_used
       FROM v_weekly_classroom_usage
       ORDER BY year_week, classroom_name`);
    res.json(rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ============ STATISTIKA: top klassid ============
/**
 * GET /api/stats/top — 5 kõige rohkem tunde kasutatud klassi (vaade v_top_classrooms).
 * Vastus: 200 [ { classroom_id, classroom_name, total_bookings, total_hours } ] | 500 { error }
 */
app.get('/api/stats/top', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM v_top_classrooms');
    res.json(rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.listen(PORT, () => {
  console.log(`Rakendus töötab: http://localhost:${PORT}`);
});
