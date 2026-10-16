# Süsteemi kirjeldus, analüüs ja nõuded

**Projekt:** arvutiklasside kasutuse andmebaas ja broneerimisrakendus
**Grupp:** TAK25
**Autor:** Olavi Keerd

## 1. Süsteemi kirjeldus

### 1.1 Probleem

Kooli arvutiklasside kasutust peetakse tihti tabelites või paberil. Siis on raske
näha, kas klass on soovitud ajal vaba. Topeltbroneeringud tulevad välja alles
tunni ajal ning statistikat klasside tegeliku kasutuse kohta pole.

### 1.2 Eesmärk

Luua keskne süsteem, mis

- hoiab ühes kohas arvutiklasse, õpetajaid/gruppe ja broneeringuid;
- ei luba sama klassi samaks ajaks topelt broneerida;
- ei luba broneerida klassi, kuhu osalejad ei mahu;
- annab statistikat klasside kasutuse kohta (tunnid nädalas, populaarseimad klassid);
- võimaldab andmeid importida olemasolevatest failidest ja eksportida aruandeid.

### 1.3 Süsteemi piirid

Süsteemi **kuulub**: klasside, kasutajate, tunnitüüpide ja broneeringute haldus,
ärireeglite kontroll, statistika, import/eksport, andmebaasi õigused ja varundus.

Süsteemi **ei kuulu** (teadlikult välja jäetud): kasutajate sisselogimine
veebiliideses, e-posti teavitused, korduvad (iganädalased) broneeringud ja
integratsioon kooli tunniplaanisüsteemiga.

### 1.4 Arhitektuur

```text
┌──────────────────┐  HTTP/JSON  ┌────────────────────┐  SQL (mysql2)  ┌──────────────┐
│  Brauser         │ ──────────► │  Node.js + Express │ ─────────────► │  MariaDB     │
│  public/         │ ◄────────── │  server.js         │ ◄───────────── │  schema.sql  │
│  index.html      │             │  validation.js     │                │  triggerid,  │
└──────────────────┘             └────────────────────┘                │  vaated      │
                                   ▲              ▲                    └──────────────┘
                     import.js ────┘              └──── export.js
              (CSV/JSON/XML → DB)                    (DB → CSV/JSON)
```

| Kiht | Komponent | Vastutus |
|------|-----------|----------|
| Esitluskiht | [app/public/index.html](app/public/index.html) | vorm, broneeringute tabel, statistika |
| Rakenduskiht | [app/server.js](app/server.js) | REST API, kattumise kontroll |
| Ärireeglid | [app/validation.js](app/validation.js) | DB-sõltumatu valideerimine (testitav) |
| Andmekiht | [schema.sql](schema.sql) | tabelid, CHECK-id, triggerid, vaated |
| Õigused | [permissions.sql](permissions.sql) | rollid `role_admin`, `role_viewer` |
| Andmevahetus | [app/import.js](app/import.js), [app/export.js](app/export.js) | failide import ja eksport |

Andmemudel on kirjeldatud failis [logical_design.md](logical_design.md) ning
diagrammidel [erd_crowsfoot.png](erd_crowsfoot.png) ja [uml_class.png](uml_class.png).
Põhialgoritm on kirjeldatud failis [algoritm.md](algoritm.md).

## 2. Analüüs

### 2.1 Huvipooled ja kasutajarollid

| Roll | Kes | Mida teeb | Tehniline vaste |
|------|-----|-----------|-----------------|
| Administraator | IT-juht | haldab andmebaasi, struktuuri ja kasutajaid | `admin_user` / `role_admin` (ALL PRIVILEGES) |
| Rakenduse kasutaja | õpetaja, sekretär | lisab, muudab ja kustutab broneeringuid veebis | `app_user` (SELECT, INSERT, UPDATE, DELETE) |
| Vaatleja | juhtkond, aruandlus | vaatab andmeid ja statistikat, ei muuda | `viewer_user` / `role_viewer` (SELECT) |

### 2.2 Kasutuslood

| ID | Kasutuslugu |
|----|-------------|
| KL-1 | Õpetajana tahan näha kõiki broneeringuid, et leida vaba aeg. |
| KL-2 | Õpetajana tahan broneerida klassi kindlaks päevaks ja kellaajaks, et viia seal läbi tund. |
| KL-3 | Õpetajana tahan saada kohe veateate, kui klass on sel ajal juba võetud. |
| KL-4 | Õpetajana tahan broneeringut muuta või kustutada, kui plaanid muutuvad. |
| KL-5 | Juhtkonnana tahan näha, mitu tundi nädalas iga klassi kasutatakse, et planeerida ressursse. |
| KL-6 | Administraatorina tahan importida olemasolevad andmed failidest, et ei peaks neid käsitsi sisestama. |
| KL-7 | Administraatorina tahan andmebaasi varundada ja taastada, et andmed ei läheks kaotsi. |

### 2.3 Põhiolemid

`classroom` (klass), `user_or_group` (õpetaja või grupp), `lesson_type` (tunni tüüp),
`booking` (broneering) ja `booking_participant` (broneeringu lisaosalejad, N:M vahetabel).
Detailne põhjendus on failis [logical_design.md](logical_design.md).

## 3. Funktsionaalsed nõuded

| ID | Nõue | Kus täidetud |
|----|------|--------------|
| FN-1 | Süsteem kuvab kõigi broneeringute nimekirja koos klassi, korraldaja ja tunnitüübi nimega. | `GET /api/bookings` |
| FN-2 | Kasutaja saab lisada uue broneeringu. | `POST /api/bookings` |
| FN-3 | Kasutaja saab olemasolevat broneeringut muuta. | `PUT /api/bookings/:id` |
| FN-4 | Kasutaja saab broneeringu kustutada. | `DELETE /api/bookings/:id` |
| FN-5 | Süsteem keeldub broneeringust, mille lõppaeg pole hilisem kui algusaeg. | `validateTimeRange`, `chk_booking_time` |
| FN-6 | Süsteem keeldub negatiivsest osalejate arvust. | `validateParticipants`, `chk_booking_participants` |
| FN-7 | Süsteem keeldub broneeringust, kus osalejaid on rohkem, kui klassi mahub. | trigger `trg_booking_capacity_*` |
| FN-8 | Süsteem keeldub broneeringust, mis kattub sama klassi teise tühistamata broneeringuga. | `checkOverlap` (vt [algoritm.md](algoritm.md)) |
| FN-9 | Broneeringul võib olla mitu lisaosalejat (gruppi/õpetajat). | tabel `booking_participant` |
| FN-10 | Süsteem näitab klasside kasutust tundides nädala kaupa. | `GET /api/stats/weekly`, vaade `v_weekly_classroom_usage` |
| FN-11 | Süsteem näitab 5 kõige kasutatumat klassi. | `GET /api/stats/top`, vaade `v_top_classrooms` |
| FN-12 | Andmeid saab importida CSV-, JSON- ja XML-failidest. | [app/import.js](app/import.js) |
| FN-13 | Aruandeid saab eksportida CSV- ja JSON-failideks. | [app/export.js](app/export.js) |
| FN-14 | Vaatleja roll saab andmeid ainult lugeda. | [permissions.sql](permissions.sql) |

## 4. Mittefunktsionaalsed nõuded

| ID | Kategooria | Nõue | Kuidas täidetud |
|----|------------|------|-----------------|
| MFN-1 | Andmete terviklus | Ärireegleid kontrollitakse nii rakenduses kui andmebaasis. | CHECK-id, triggerid ja välisvõtmed + `validation.js` |
| MFN-2 | Turvalisus | SQL-päringud on parametriseeritud. | `?` kohatäitjad kõigis päringutes |
| MFN-3 | Turvalisus | Andmebaasi mandaate pole koodis, need tulevad keskkonnamuutujatest. | [app/db.js](app/db.js) |
| MFN-4 | Turvalisus | Õigused jagatakse vähima õiguse põhimõttel. | rollid admin / viewer / app_user |
| MFN-5 | Töökindlus | Import toimub ühe tehinguna: vea korral keeratakse kõik tagasi. | `beginTransaction` / `rollback` failis `import.js` |
| MFN-6 | Töökindlus | Andmebaasi saab varundada ja taastada. | [backup_restore.md](backup_restore.md), [backup/](backup/) |
| MFN-7 | Jõudlus | Kattumise kontroll ei loe kogu tabelit. | indeks `idx_booking_classroom_date` |
| MFN-8 | Kasutatavus | Veateated on eesti keeles ja arusaadavad. | `res.status(...).json({ error })` |
| MFN-9 | Hooldatavus | Ärireeglid on üksustestidega kaetud ja CI käivitab testid igal PR-il. | [app/test/](app/test/), [.github/workflows/ci.yml](.github/workflows/ci.yml) |
| MFN-10 | Hooldatavus | Kood on dokumenteeritud ühtse päise ja JSDoc-kommentaaridega. | [dokumenteerimine.md](dokumenteerimine.md) |
| MFN-11 | Ühilduvus | Töötab Node.js 18+ ja MariaDB/MySQL-iga. | [app/README.md](app/README.md) |

## 5. Piirangud ja eeldused

- Andmebaasimootor on MariaDB, sest SQLite ei toeta rolle ega `GRANT`/`REVOKE`-i (vt [permissions.md](permissions.md)).
- Broneering mahub ühe kalendripäeva sisse (üle südaöö ei ulatu).
- Veebiliideses pole sisselogimist. Rakendus kasutab ühte `app_user` kontot ja on mõeldud kohalikuks või sisevõrgu kasutuseks.
- Samaaegsete broneeringute võidujooksu piirang on kirjeldatud failis [algoritm.md](algoritm.md), punkt 6.

## 6. Projektihaldus

- **Git / GitHub**: iga muudatus tehakse eraldi harus ja liidetakse pull requestiga.
  `master` haru on kaitstud ja nõuab rohelist CI-d (vt [AI_QUALITY_PLAN.md](AI_QUALITY_PLAN.md),
  [branch_protection_proof.txt](branch_protection_proof.txt)).
- **Trello**: ülesannete tahvel (veerud *To Do → Doing → Review → Done*). Iga kaart
  vastab ühele nõudele või alamülesandele ja viitab vastavale pull requestile.
