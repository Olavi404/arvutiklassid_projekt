# Dokumenteerimise tavad

See fail kirjeldab, kuidas selles projektis koodi ja dokumentatsiooni kirjutatakse.
Eesmärk on, et iga fail oleks arusaadav ka inimesele, kes seda esimest korda avab.

## 1. Faili päis (header)

Iga lähtekoodifaili alguses on päis, mis vastab küsimustele: *mis see fail on,
kes selle tegi, millal ja kuidas seda kasutada*.

### JavaScript (`app/*.js`)

```js
/**
 * @file        server.js
 * @description Express REST API arvutiklasside broneeringute haldamiseks (CRUD + statistika).
 * @author      Olavi Keerd (TAK25)
 * @created     2026-07-09
 * @modified    2026-10-16
 *
 * Käivitamine: DB_USER=app_user DB_PASS=app_pass_123 PORT=3000 node server.js
 */
```

| Väli | Kohustuslik | Sisu |
|------|-------------|------|
| `@file` | jah | faili nimi |
| `@description` | jah | 1–2 lausega, mida fail teeb |
| `@author` | jah | autor(id) ja grupp |
| `@created` | jah | loomise kuupäev `YYYY-MM-DD` |
| `@modified` | jah | viimase sisulise muudatuse kuupäev |
| Käivitamine / sõltuvused | kui fail on käivitatav skript | käsk ja vajalikud keskkonnamuutujad |

### SQL (`*.sql`)

```sql
-- ============================================================
-- Arvutiklasside kasutuse andmebaas
-- Projekt: TAK25
-- Andmebaasimootor: MariaDB / MySQL
-- ============================================================
```

SQL-failides on iga tabeli, triggeri ja vaate ees plokk-kommentaar, mis selgitab
selle otstarvet (vt [schema.sql](schema.sql)).

## 2. Funktsioonide kommenteerimine (JSDoc)

Iga eksporditud või mittetriviaalne funktsioon saab JSDoc-ploki:

```js
/**
 * Kontrollib, kas lõppaeg on hilisem kui algusaeg.
 * @param {string} startTime "HH:MM" formaadis
 * @param {string} endTime "HH:MM" formaadis
 * @returns {string|null} veateade või null, kui kehtiv
 */
```

- Esimene rida ütleb, **mida** funktsioon teeb (mitte kuidas).
- `@param` iga parameetri kohta: tüüp, nimi ja vajadusel formaat.
- `@returns`: tagastatava väärtuse tüüp ja tähendus.
- API marsruutide puhul on lisaks kirjas HTTP meetod, tee ja võimalikud vastuskoodid.

## 3. Reasisesed kommentaarid

- Kommentaar selgitab, **miks** midagi tehakse, mitte **mida** kood teeb. Seda näeb koodist niigi.
  - ✗ `// suurenda loendurit`
  - ✓ `// Muutmisel jäta broneering ise välja, muidu kattuks see iseendaga`
- Viita ärireeglile numbriga (nt `ärireegel 4`), et seos [logical_design.md](logical_design.md)-ga oleks jälgitav.
- Suuremad loogilised plokid eraldatakse sektsioonipäisega: `// ============ CREATE: uus broneering ============`.
- Ära jäta koodi välja kommenteeritud koodiridu. Vana versioon on Git-i ajaloos olemas.
- Kui koodi muudad, uuenda ka kommentaari. Vale kommentaar on hullem kui kommentaari puudumine.

## 4. Keel

- Kommentaarid, dokumentatsioon ja kasutajale näidatavad veateated on **eesti keeles**.
- Koodi identifikaatorid (muutujad, funktsioonid, tabelid, väljad) on **inglise keeles**.

## 5. Projekti dokumendid

| Fail | Sisu |
|------|------|
| [app/README.md](app/README.md) | paigaldus, käivitamine, konfiguratsioon |
| [nouded.md](nouded.md) | süsteemi kirjeldus, analüüs, funktsionaalsed ja mittefunktsionaalsed nõuded |
| [algoritm.md](algoritm.md) | broneeringu valideerimise ja kattumise kontrolli algoritm |
| [logical_design.md](logical_design.md) | andmemudel, N:M seos, ärireeglid |
| [permissions.md](permissions.md) | rollid ja õigused |
| [backup_restore.md](backup_restore.md) | varundamine ja taastamine |
| [AGENTS.md](AGENTS.md) | reeglid AI-agentidele |
| `dokumenteerimine.md` | see fail |

## 6. Git ja commitid

- Commiti sõnum on eesti keeles ja käskivas kõneviisis: *„Lisa …“*, *„Paranda …“*.
- Iga muudatus tehakse eraldi harus (`feat/...`, `fix/...`, `docs/...`) ja liidetakse pull requestiga.
- PR-i kirjelduses on täidetud kontrollnimekiri ([.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md)).
