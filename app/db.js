// db.js — jagatud andmebaasiühendus (MariaDB / MySQL)
import mysql from 'mysql2/promise';

// Keskkonnamuutujad võimaldavad muuta ühendust ilma koodi muutmata.
export const dbConfig = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME || 'arvutiklassid',
  multipleStatements: true,
  socketPath: process.env.DB_SOCKET || undefined,
};

export const pool = mysql.createPool({
  ...dbConfig,
  waitForConnections: true,
  connectionLimit: 10,
});
