/**
 * @file        validation.js
 * @description Broneeringu ärireeglite 1 ja 2 valideerimine. DB-sõltumatu, et seda
 *              saaks üksustestida ilma andmebaasita (vt test/validation.test.js).
 * @author      Olavi Keerd (TAK25)
 * @created     2026-07-09
 * @modified    2026-07-09
 */

/**
 * Kontrollib, kas lõppaeg on hilisem kui algusaeg.
 * @param {string} startTime "HH:MM" formaadis
 * @param {string} endTime "HH:MM" formaadis
 * @returns {string|null} veateade või null, kui kehtiv
 */
export function validateTimeRange(startTime, endTime) {
  if (endTime <= startTime) {
    return 'Lõppaeg peab olema hilisem kui algusaeg';
  }
  return null;
}

/**
 * Kontrollib, et osalejate arv ei oleks negatiivne.
 * @param {number|string} participantsCount
 * @returns {string|null} veateade või null, kui kehtiv
 */
export function validateParticipants(participantsCount) {
  if (Number(participantsCount) < 0) {
    return 'Osalejate arv ei saa olla negatiivne';
  }
  return null;
}

/**
 * Käivitab kõik väljal-põhised (DB-sõltumatud) valideerimisreeglid broneeringu jaoks.
 * Ajalise kattumise kontroll (checkOverlap) jääb server.js-i, kuna see vajab andmebaasi.
 * @param {{start_time: string, end_time: string, participants_count: number|string}} booking
 * @returns {string|null} esimene leitud veateade või null, kui kõik on kehtiv
 */
export function validateBookingFields(booking) {
  return (
    validateTimeRange(booking.start_time, booking.end_time) ||
    validateParticipants(booking.participants_count)
  );
}
