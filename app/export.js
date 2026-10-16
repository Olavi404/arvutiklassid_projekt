/**
 * @file        export.js
 * @description Ekspordib aruanded CSV ja JSON formaatidesse:
 *                export/bookings_summary.csv  — broneeringute koond kuu ja klassi kaupa
 *                export/top5_classes.json     — top 5 kõige kasutatumat klassi
 * @author      Olavi Keerd (TAK25)
 * @created     2026-07-09
 * @modified    2026-07-09
 *
 * Käivitamine: DB_USER=app_user DB_PASS=app_pass_123 node export.js
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from './db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const EXPORT_DIR = path.resolve(__dirname, '..', 'export');

/**
 * Kirjutab faili bookings_summary.csv broneeringute arvu, osalejate summa ja tundide
 * koondi kuu ja klassi kaupa. Tühistatud broneeringuid ei arvestata.
 * @param {import('mysql2/promise').PoolConnection} conn
 */
async function exportSummaryCSV(conn) {
  const [rows] = await conn.query(`
    SELECT
      DATE_FORMAT(b.booking_date, '%Y-%m') AS month,
      c.name AS classroom,
      COUNT(b.id) AS bookings,
      SUM(b.participants_count) AS total_participants,
      ROUND(SUM(TIME_TO_SEC(TIMEDIFF(b.end_time, b.start_time)))/3600, 2) AS hours
    FROM booking b
    JOIN classroom c ON c.id = b.classroom_id
    WHERE b.status <> 'cancelled'
    GROUP BY month, c.name
    ORDER BY month, c.name`);

  const header = 'month,classroom,bookings,total_participants,hours';
  const lines = rows.map(r =>
    `${r.month},${r.classroom},${r.bookings},${r.total_participants},${r.hours}`);
  const csv = [header, ...lines].join('\n') + '\n';
  fs.writeFileSync(path.join(EXPORT_DIR, 'bookings_summary.csv'), csv, 'utf-8');
  console.log(`  bookings_summary.csv: ${rows.length} rida`);
}

/**
 * Kirjutab faili top5_classes.json 5 kõige rohkem kasutatud klassiga (vaade v_top_classrooms).
 * @param {import('mysql2/promise').PoolConnection} conn
 */
async function exportTop5JSON(conn) {
  const [rows] = await conn.query('SELECT * FROM v_top_classrooms');
  const out = {
    generated_at: new Date().toISOString(),
    description: 'Top 5 kõige kasutatumad arvutiklassid (tundide järgi)',
    classrooms: rows.map((r, i) => ({
      rank: i + 1,
      classroom_id: r.classroom_id,
      name: r.classroom_name,
      total_bookings: r.total_bookings,
      total_hours: Number(r.total_hours),
    })),
  };
  fs.writeFileSync(
    path.join(EXPORT_DIR, 'top5_classes.json'),
    JSON.stringify(out, null, 2), 'utf-8');
  console.log(`  top5_classes.json: ${rows.length} klassi`);
}

/** Käivitab mõlemad ekspordid ja sulgeb lõpus andmebaasiühenduse. */
async function main() {
  const conn = await pool.getConnection();
  try {
    console.log('Ekspordin andmed...');
    await exportSummaryCSV(conn);
    await exportTop5JSON(conn);
    console.log('Eksport õnnestus. Failid kaustas export/');
  } catch (err) {
    console.error('Eksport ebaõnnestus:', err.message);
    process.exitCode = 1;
  } finally {
    conn.release();
    await pool.end();
  }
}

main();
