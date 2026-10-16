/**
 * @file        db.js
 * @description Jagatud andmebaasiühenduse konfiguratsioon ja ühenduste kogum (MariaDB / MySQL).
 * @author      Olavi Keerd (TAK25)
 * @created     2026-07-09
 * @modified    2026-07-09
 *
 * Keskkonnamuutujad: DB_HOST, DB_PORT, DB_USER, DB_PASS, DB_NAME, DB_SOCKET
 */
import mysql from 'mysql2/promise';

/**
 * Ühenduse seaded. Keskkonnamuutujad võimaldavad muuta ühendust ilma koodi muutmata
 * ja hoiavad paroolid koodist väljas.
 */
export const dbConfig = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME || 'arvutiklassid',
  multipleStatements: true,
  socketPath: process.env.DB_SOCKET || undefined,
};

/** Ühenduste kogum (max 10 samaaegset ühendust), mida jagavad server, import ja eksport. */
export const pool = mysql.createPool({
  ...dbConfig,
  waitForConnections: true,
  connectionLimit: 10,
});
