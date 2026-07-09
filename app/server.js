// server.js — Express CRUD rakendus arvutiklasside broneeringute jaoks
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from './db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// --- Abifunktsioon: kontrolli ajalist kattumist (ärireegel 4) ---
async function checkOverlap(classroomId, date, start, end, excludeId = null) {
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
app.get('/api/lookups', async (req, res) => {
  try {
    const [classrooms] = await pool.query('SELECT id, name, capacity FROM classroom ORDER BY name');
    const [users] = await pool.query('SELECT id, name, type FROM user_or_group ORDER BY name');
    const [types] = await pool.query('SELECT id, name FROM lesson_type ORDER BY name');
    res.json({ classrooms, users, types });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ============ READ: kõik broneeringud (list) ============
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
app.post('/api/bookings', async (req, res) => {
  try {
    const { classroom_id, organizer_id, lesson_type_id, booking_date,
            start_time, end_time, participants_count, status } = req.body;

    if (end_time <= start_time)
      return res.status(400).json({ error: 'Lõppaeg peab olema hilisem kui algusaeg' });
    if (Number(participants_count) < 0)
      return res.status(400).json({ error: 'Osalejate arv ei saa olla negatiivne' });
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
app.put('/api/bookings/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { classroom_id, organizer_id, lesson_type_id, booking_date,
            start_time, end_time, participants_count, status } = req.body;

    if (end_time <= start_time)
      return res.status(400).json({ error: 'Lõppaeg peab olema hilisem kui algusaeg' });
    if (Number(participants_count) < 0)
      return res.status(400).json({ error: 'Osalejate arv ei saa olla negatiivne' });
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
app.delete('/api/bookings/:id', async (req, res) => {
  try {
    const [r] = await pool.query('DELETE FROM booking WHERE id=?', [req.params.id]);
    if (r.affectedRows === 0) return res.status(404).json({ error: 'Broneeringut ei leitud' });
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ============ STATISTIKA: klasside kasutus tundides nädalas ============
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
app.get('/api/stats/top', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM v_top_classrooms');
    res.json(rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.listen(PORT, () => {
  console.log(`Rakendus töötab: http://localhost:${PORT}`);
});
