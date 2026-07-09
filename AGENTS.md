# AGENTS.md

Reeglid AI-agentidele, kes teevad muudatusi selles repos. Fail on valitud
nimega `AGENTS.md`, kuna see on tööriistast sõltumatu, avatud standard,
mida loevad natiivselt paljud levinud AI-koodiagendid (OpenAI Codex,
Cursor, Windsurf, Gemini CLI, GitHub Copilot jt).

**Märkus Claude Code kasutajatele:** Claude Code ei loe `AGENTS.md`-i
natiivselt (seisuga käesoleva faili loomine) — see kasutab oma formaati
`CLAUDE.md`. Kui projektis kasutatakse Claude Code'i, loo lisaks väike
`CLAUDE.md` fail sisuga `Strictly follow the rules in ./AGENTS.md`, või
tee sümbolviide (`ln -s AGENTS.md CLAUDE.md`), et sama reeglistik kehtiks.

## 1. Projekti lühikirjeldus

See on **arvutiklasside broneerimissüsteem** (õppeprojekt, grupp TAK25):
Node.js/Express backend + MariaDB andmebaas + lihtne staatiline HTML/JS
frontend. Projekt katab andmemudeli disaini, CRUD-i, impordi/ekspordi,
rollipõhiseid õigusi ja varundamist/taastamist.

Peamised kaustad ja failid:

- `schema.sql` — andmebaasi struktuur (tabelid, CHECK-piirangud, triggerid, vaated). **Kriitiline.**
- `permissions.sql` / `permissions.md` — rollid ja GRANT/REVOKE õigused. **Kriitiline.**
- `logical_design.md` — loogilise disaini kirjeldus (N:M seosed, normaliseerimine).
- `erd.dbml`, `erd_crowsfoot.*`, `uml_class.*` — diagrammid (ERD, UML). Genereeritud failid — ära muuda käsitsi, muuda lähtefaili (`.dbml`/`.dot`) ja genereeri uuesti.
- `app/server.js` — Express API (CRUD-marsruudid broneeringute jaoks). **Kriitiline.**
- `app/validation.js` — DB-sõltumatud ärireeglid (aja- ja osalejate valideerimine). **Kriitiline, testitud.**
- `app/db.js` — andmebaasiühenduse konfiguratsioon (keskkonnamuutujatest).
- `app/import.js` / `app/export.js` — CSV/JSON/XML import ja CSV/JSON eksport.
- `app/public/` — staatiline frontend (`index.html` + ekraanipildid).
- `app/test/` — üksustestid (`node --test`).
- `import/`, `export/` — näidisandmed impordiks/ekspordiks.
- `backup/`, `backup_restore.md` — varundamise ja taastamise tõendus.

**Kriitilised osad, kus vead on kõige kulukamad:** andmebaasi skeem
(`schema.sql`), õigused (`permissions.sql`), ja ärireeglite valideerimine
(`app/validation.js`, `app/server.js` CRUD-marsruudid). Nende muutmine
mõjutab otseselt andmete terviklust.

## 2. Arenduskäsud

Kõik käsud käivitatakse `app/` kaustast, kui pole öeldud teisiti.

- Sõltuvuste paigaldamine: `npm install`
- Rakenduse käivitamine: `DB_USER=app_user DB_PASS=app_pass_123 PORT=3000 node server.js`
- Testide käivitamine: `npm test`
- Lindi käivitamine: `npm run lint`
- Andmete import: `DB_USER=app_user DB_PASS=app_pass_123 node import.js`
- Andmete eksport: `DB_USER=app_user DB_PASS=app_pass_123 node export.js`
- Andmebaasi skeemi loomine (repo juurest): `mysql -u root < schema.sql`
- Õiguste seadistamine (repo juurest): `mysql -u root < permissions.sql`

Projektis ei ole hetkel build-sammu ega type-checki (puhas JavaScript,
mitte TypeScript) — seega need pole nõutud kontrollnimekirjas.

## 3. Koodistiil ja kokkulepped

- Kasuta ES-moodulite süntaksit (`import`/`export`), mitte `require`.
- DB-sõltumatud ärireeglid kuuluvad `validation.js`-i, mitte `server.js`-i —
  see hoiab need testitavana ilma andmebaasita.
- SQL-päringud tee alati parametriseeritud kujul (`?` platsihoidjad), mitte
  string-liitmisega — kaitseb SQL-i süstimise eest.
- Järgi olemasolevat vastuse kuju API marsruutides: `res.json(...)` õnnestumisel,
  `res.status(xxx).json({ error: '...' })` veal.
- Veateated frontendi jaoks on eesti keeles (kasutaja poole suunatud tekst) —
  säilita see tava uutes veateadetes.
- Ära lisa uut raamistikku (nt TypeScript, uus ORM) ilma selgituseta, miks
  olemasolev lahendus (Express + mysql2) ei sobi.

## 4. Testimise reeglid

- Uus funktsionaalsus (uued ärireeglid, uued API marsruudid) peab sisaldama teste `app/test/` kaustas.
- Bugifixid peavad sisaldama regressioonitesti, mis **ebaõnnestub enne parandust ja õnnestub pärast** — vt näidet `app/test/validation.test.js` failis ("lükkab tagasi, kui lõpp võrdub algusega").
- Ära eemalda olemasolevaid teste, välja arvatud juhul, kui need on selgelt aegunud — sel juhul selgita põhjust muudatuse kokkuvõttes.
- Enne töö valmisolevaks märkimist käivita kogu testikomplekt: `npm test`.
- DB-sõltuvat loogikat (nt `checkOverlap` funktsioon `server.js`-is) ei pea üksustestima ilma andmebaasita, aga muudatused sellele tuleb kirjeldada kokkuvõttes ja võimalusel käsitsi testida käivitatud andmebaasi vastu.

## 5. Branch'i ja main haru kaitsmise reeglid

- Ära tee kunagi commit'e otse `main`/`master` harusse.
- Loo iga muudatuse jaoks eraldi feature-branch (nimeformaat nt `fix/...`, `feat/...`).
- Hoia pull request'id väikesed ja fokuseeritud ühele teemale.
- Ära märgi tööd valmisolevaks, kui testid, lint, või build ebaõnnestuvad.
- Selgita lõppkokkuvõttes iga muudetud faili ja põhjust, miks see muudeti.

**Tähtis:** see reeglite fail üksi ei kaitse `main` haru. Tehniline kaitse
CI-kontrollide osas on juba olemas (`.github/workflows/ci.yml` käivitab
testid ja lindi igal PR-il ja push'il), samuti on olemas PR template
(`.github/PULL_REQUEST_TEMPLATE.md`) kontrollnimekirjaga. Branch protection
ja kohustuslik PR review GitHubi seadetes tuleb seadistada eraldi
(vt `AI_QUALITY_PLAN.md`).

## 6. Muudatuste ulatuse piiramine

- Muuda ainult faile, mis on otseselt seotud antud ülesandega.
- Ära refaktori mitteseotud koodi "parema stiili" nimel samas muudatuses.
- Ära nimeta ümber avalikke funktsioone, API marsruute, andmebaasi välju
  ega tabeleid ilma selgesõnalise palveta — need mõjutavad frontendi,
  importi/eksporti ja backup/restore skripte.
- Kui muudatus nõuab rohkem kui 5 faili puudutamist, selgita enne
  muutmist, miks see on vajalik.

## 7. Turvalisuse ja andmete kaitse reeglid

- Ära kunagi commiti saladusi: paroole, API-võtmeid, tokeneid. Andmebaasi
  mandaadid tulevad ainult keskkonnamuutujatest (vt `app/db.js` mustrit),
  mitte kõvakodeeritult koodi.
- README-s ja skriptides nähtavad näidisparoolid (nt `app_pass_123`) on
  ainult kohaliku arenduse jaoks — ära lisa tootmis- ega päris mandaate
  samale kujule.
- Ära logi tundlikke kasutajaandmeid (nt osalejate isikuandmeid) console.log-iga.
- Valideeri kasutaja sisend alati serveri poolel (nagu praegu tehtud
  `validation.js`-is) — ära usalda ainult kliendipoolset valideerimist.
- Ära keela ega jäta vahele autentimis-/autoriseerimiskontrolle
  (rollid, GRANT/REVOKE), et teste "lihtsamalt" läbida.

## 8. Dependency'de lisamise reeglid

- Ära lisa uusi tootmissõltuvusi ilma selgituseta, miks olemasolevatest
  (`express`, `mysql2`, `fast-xml-parser`) ei piisa.
- Kontrolli enne uue paketi lisamist, kas sama funktsionaalsus on juba
  olemas Node.js sisseehitatud moodulitega (nt testimiseks kasutame
  `node --test`, mitte Jest/Mocha, et vältida lisasõltuvust).
- Arendussõltuvused (nt `eslint`) lisa `devDependencies` alla, mitte `dependencies`.

## 9. Enne töö lõpetamist tehtav kontrollnimekiri

Enne kui väidad, et ülesanne on valmis:

- [ ] Vaata muudetud failid üle.
- [ ] Käivita testid: `npm test`.
- [ ] Käivita lint: `npm run lint`.
- [ ] Kinnita, et ühtegi mitteseotud faili pole muudetud.
- [ ] Kinnita, et ühtegi saladust (parool, võti) pole lisatud.
- [ ] Kui muutsid andmebaasi skeemi või õigusi, kontrolli käsitsi vastu käivitatud MariaDB instantsi.
- [ ] Tee kokkuvõte: mis muutus ja miks.

## 10. AI käitumisreeglid ebakindluse korral

- Küsi selgitust enne, kui muudad andmebaasi skeemi (`schema.sql`),
  õiguste mudelit (`permissions.sql`), autentimist või avalikke API
  marsruute — need mõjutavad kogu süsteemi tervikluse.
- Kui nõue on ebaselge, paku enne koodi kirjutamist lühike plaan.
- Kui testid ebaõnnestuvad ja põhjus pole selge, raporteeri ebaõnnestumine
  ausalt, mitte ära arva ega peida seda.
- Kui pead valima mitme lahenduse vahel, eelista lihtsamat ja olemasoleva
  koodistiiliga kooskõlas olevat varianti.
