// test/validation.test.js — üksustestid broneeringu ärireeglitele
// Käivitamine: npm test (kasutab Node.js sisseehitatud test runnerit, node --test)

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateTimeRange, validateParticipants, validateBookingFields } from '../validation.js';

// --- validateTimeRange ---

test('validateTimeRange: lubab kehtiva vahemiku (algus enne lõppu)', () => {
  assert.equal(validateTimeRange('09:00', '10:00'), null);
});

test('validateTimeRange: lükkab tagasi, kui lõpp on enne algust', () => {
  const error = validateTimeRange('10:00', '09:00');
  assert.equal(error, 'Lõppaeg peab olema hilisem kui algusaeg');
});

test('validateTimeRange: lükkab tagasi, kui lõpp võrdub algusega', () => {
  // Regressioonitest: varasem viga lubas end_time === start_time läbi minna,
  // kuna võrdlus oli kunagi `end_time < start_time` (mitte <=).
  // See test peab ebaõnnestuma, kui keegi taastab vale võrdlusoperaatori.
  const error = validateTimeRange('09:00', '09:00');
  assert.equal(error, 'Lõppaeg peab olema hilisem kui algusaeg');
});

// --- validateParticipants ---

test('validateParticipants: lubab positiivset arvu', () => {
  assert.equal(validateParticipants(15), null);
});

test('validateParticipants: lubab nulli', () => {
  assert.equal(validateParticipants(0), null);
});

test('validateParticipants: lükkab tagasi negatiivse arvu', () => {
  const error = validateParticipants(-1);
  assert.equal(error, 'Osalejate arv ei saa olla negatiivne');
});

test('validateParticipants: lükkab tagasi negatiivse arvu, mis on antud stringina', () => {
  const error = validateParticipants('-5');
  assert.equal(error, 'Osalejate arv ei saa olla negatiivne');
});

// --- validateBookingFields (kombineeritud kontroll) ---

test('validateBookingFields: tagastab null, kui kõik väljad on kehtivad', () => {
  const booking = { start_time: '08:00', end_time: '09:30', participants_count: 20 };
  assert.equal(validateBookingFields(booking), null);
});

test('validateBookingFields: tagastab ajavea enne osalejate viga, kui mõlemad on vigased', () => {
  const booking = { start_time: '10:00', end_time: '09:00', participants_count: -3 };
  assert.equal(validateBookingFields(booking), 'Lõppaeg peab olema hilisem kui algusaeg');
});

test('validateBookingFields: tagastab osalejate vea, kui ainult see on vigane', () => {
  const booking = { start_time: '08:00', end_time: '09:00', participants_count: -1 };
  assert.equal(validateBookingFields(booking), 'Osalejate arv ei saa olla negatiivne');
});
