# AI_QUALITY_PLAN.md — Kvaliteediväravate plaan

## 1. Millise AI reeglite faili valisid ja miks?

Valisin **`AGENTS.md`**. Põhjus: see on tööriistast sõltumatu, avatud
formaat, mida toetavad natiivselt paljud levinud AI-koodiagendid — nt
OpenAI Codex, Cursor, Windsurf, Google Gemini CLI, GitHub Copilot — ja mis
on nüüdseks Linux Foundationi Agentic AI Foundationi hallata antud avatud
standard. Erinevalt tootepõhistest failidest (nt `CLAUDE.md`) ei sunni
`AGENTS.md` tulevikus konkreetset tööriista valima.

**Oluline täpsustus, mille uurimise käigus avastasin:** Claude Code ise
**ei loe `AGENTS.md`-i natiivselt** — see kasutab oma formaati `CLAUDE.md`.
See on ametlikult dokumenteeritud ja kajastub ka avatud GitHubi
probleemis (anthropics/claude-code #6235), kus on palutud sellele
formaadile tuge lisada, kuid Anthropic pole seda seni teinud. Praktikas
soovitatakse Claude Code kasutajatel kas luua `CLAUDE.md`, mis viitab
`@AGENTS.md`-ile ("Strictly follow the rules in ./AGENTS.md"), või teha
sümbolviide (`ln -s AGENTS.md CLAUDE.md`). Kuna ei ole teada, millist
konkreetset AI-tööriista projekti käigus kasutatakse, valisin ikkagi
`AGENTS.md` kui laiema levikuga, tulevikukindlama valiku — kui kasutatakse
konkreetselt Claude Code'i, saab lisada väikese `CLAUDE.md`, mis viitab
sellele failile.

## 2. Milliseid kolme kuni viit allikat kasutasid?

1. **agents.md ametlik veebileht** (https://agents.md/) — formaadi
   ametlik kirjeldus: "README agentidele", soovituslikud peatükid
   (build, testid, stiil, turvalisus), ja nimekiri tööriistadest, mis
   formaati toetavad.
2. **GitHub issue anthropics/claude-code #6235** ("Feature Request:
   Support AGENTS.md") — kinnitas, et Claude Code ei toeta `AGENTS.md`-i
   natiivselt, ja andis põhjenduse, miks paljud arendajad eelistavad
   tööriistaülest formaati (koostöö teiste arendajate ja tööriistadega,
   kes ei kasuta sama AI-agenti).
3. **InfoQ artikkel "AGENTS.md Emerges as Open Standard for AI Coding
   Agents"** — kinnitas formaadi laialdast levikut (20 000+ repot) ja
   positsiooni README-t täiendava, mitte asendava failina.
4. **Projekti enda olemasolev dokumentatsioon** — `app/README.md`,
   `logical_design.md`, `permissions.md`, `backup_restore.md` — nendest
   võeti projekti tegelikud käsud ja ärireeglid, et vältida geneerilisi
   lauseid `AGENTS.md`-is.
5. **Node.js ja ESLint ametlik dokumentatsioon** — kasutati testimis- ja
   lindimisvahendite valikul (sisseehitatud `node --test` versus
   lisasõltuvus nagu Jest, ning ESLint 9 flat config formaat).

## 3. Millised on sinu projekti kõige suuremad riskid AI-ga arendamisel?

- **Andmebaasi skeemi või õiguste vaikimisi muutmine.** Suurim risk on, et
  AI "parandab" või "lihtsustab" `schema.sql`-i või `permissions.sql`-i
  ilma kontekstita, murdes olemasolevad CHECK-piirangud, triggerid või
  GRANT/REVOKE õigused, mis on hoolikalt läbi mõeldud (vt `logical_design.md`,
  `permissions.md`).
- **Ärireeglite dubleerimine/lahknemine.** Valideerimisloogika eksisteeris
  varem kolmes kohas korraga (POST, PUT marsruudid identsel kujul) — AI
  võinuks ühte kohta parandada ja teise unustada. See on nüüd lahendatud
  eraldi `validation.js`-i moodulisse tõstmisega ja testidega kaetud.
- **Vaikimisi levinud "kosmeetilised" refaktorid**, mis puudutavad rohkem
  faile kui vaja (nt muutujate ümbernimetamine kogu koodibaasis), tuues
  kaasa suure, raskesti ülevaadatava diffi.
- **Saladuste (näidisparoolide) sattumine tootmiskoodi** — README-s on
  näidisparool `app_pass_123` arendustarbeks; risk on, et AI kopeerib
  selle "reaalse" väärtusena tootmiskonfiguratsiooni.

## 4. Kuidas sinu reeglid aitavad vältida katkise koodi jõudmist main harusse?

`AGENTS.md` peatükk 5 keelab otsesed commit'id `main` harusse ja nõuab
feature-branch'e väikeste PR-idena. Peatükk 9 (kontrollnimekiri) nõuab, et
testid ja lint peavad õnnestuma **enne** töö valmisolevaks märkimist. Need
reeglid ise ei ole tehniline tõke — need suunavad AI käitumist, kuid ei
sunni midagi. Reaalne kaitse tuleb GitHubi tehnilistest mehhanismidest
(vt punkt 7 allpool).

## 5. Millised käsud peavad enne muudatuse lõpetamist õnnestuma?

- `npm test` (Node.js sisseehitatud test runner, `app/test/` kaustas olevad testid)
- `npm run lint` (ESLint)

Tõendus, et mõlemad käsud töötavad ja läbivad puhtalt, on failis
`quality_check_proof.txt` repo juurkaustas.

Projektis puudub praegu eraldi build- või type-check samm (puhas
JavaScript, ilma TypeScriptita), seega neid kontrollnimekirja ei lisatud —
see on ausalt kirjas ka `AGENTS.md`-is, et vältida valeväidet olematu
sammu kohta.

## 6. Kuidas tagad, et vana töötav funktsionaalsus ei lähe katki?

- Ärireeglite valideerimine (aja- ja osalejate kontrollid) eraldati
  omaette moodulisse `validation.js` **ilma käitumist muutmata** —
  `server.js` kutsub nüüd samu funktsioone, mis varem olid inline'itud.
  See on minimaalne, jälgitav refaktor, mitte ümberkirjutus.
- Lisati regressioonitest ("lükkab tagasi, kui lõpp võrdub algusega"),
  mis konkreetselt kontrollib piirjuhtu (`end_time === start_time`),
  kus varasem võrdlusviga oleks võinud kergesti tekkida (`<` vs `<=`).
  See test tabab, kui keegi (AI või inimene) tuleviku muudatuses
  taastaks vale võrdlusoperaatori.
- Testid katavad nii kehtivaid kui vigaseid sisendeid (positiivne arv,
  null, negatiivne arv, string-kujul negatiivne arv), mitte ainult
  "õnneliku raja" juhtumeid.
- `AGENTS.md` peatükk 4 nõuab otsesõnu, et olemasolevaid teste ei
  eemaldata ilma põhjenduseta, ja et bugifixidele lisatakse alati
  regressioonitest.

## 7. Millised reeglid vajavad lisaks tehnilist tuge (CI, branch protection, PR review)?

Reeglite fail üksi ei garanteeri midagi — järgnev tehniline tugi on vajalik:

- **GitHub Actions CI workflow**, mis käivitab `npm test` ja `npm run lint`
  automaatselt iga pull request'i peale (`app/` kaustas).
- **Branch protection reegel `main` harule**, mis nõuab rohelist CI staatust
  enne merge'imist ja keelab otsese push'i.
- **Pull request review nõue** (vähemalt üks kinnitus enne merge'imist),
  et keegi vaataks üle ka AI genereeritud muudatused andmebaasi skeemis
  või õigustes, kuna need on kõige kriitilisemad ja kõige raskemini
  automaattestidega kaetavad osad (nõuavad käivitatud MariaDB instantsi).
- **PR template**, kus arendaja/AI peab kinnitama, et `npm test` ja
  `npm run lint` on lokaalselt läbitud enne PR-i avamist.

Neist praegu on repos rakendatud reeglite fail, testid/lint ise,
**GitHub Actions CI workflow** (`.github/workflows/ci.yml`, käivitab
`npm ci`, `npm run lint` ja `npm test` igal pull request'il ja push'il
`main`/`master` harusse) ning **PR template**
(`.github/PULL_REQUEST_TEMPLATE.md`), kus arendaja või AI peab kinnitama
kontrollnimekirja täitmist. Branch protection (nõue, et CI peab olema
roheline enne merge'imist) on seadistatav ainult GitHubi veebiliidese/repo
seadete kaudu ja jääb hetkel käsitsi tehtavaks sammuks — vt allpool juhist.

### Boonusülesanded — mis on tehtud

- ✅ GitHub Actions CI workflow, mis käivitab testid automaatselt iga
  pull request'i korral (`.github/workflows/ci.yml`).
- ✅ Regressioonitest varasema (potentsiaalse) bugi kohta — vt
  `app/test/validation.test.js`, test "lükkab tagasi, kui lõpp võrdub
  algusega".
- ✅ PR template, kus arendaja või AI peab kinnitama, et testid on
  läbitud (`.github/PULL_REQUEST_TEMPLATE.md`).
- ⬜ Branch protection — nõuab käsitsi seadistamist GitHubi veebiliideses
  (vt juhis allpool), ei ole failina lisatav.
- ⬜ Eraldi reeglid frontendile ja backendile — praeguses projektis on
  frontend väga õhuke (staatiline `app/public/index.html`), mistõttu
  ühine `AGENTS.md` katab mõlemat piisavalt; eraldi failid poleks
  praegu sisulist väärtust lisanud.

### Branch protection seadistamine (käsitsi samm GitHubis)

CI workflow ise ei blokeeri merge'imist, kui seda GitHubi seadetes eraldi
ei nõuta. Selleks, et `main` haru oleks tegelikult kaitstud:

1. Mine repos: **Settings → Branches → Add branch protection rule**.
2. Vali `main` (või `master`) haru.
3. Lülita sisse **"Require status checks to pass before merging"** ja
   vali kontrolliks CI workflow'i `test-and-lint` job.
4. Soovi korral lülita sisse ka **"Require a pull request before merging"**
   ja **"Require approvals"** (vähemalt 1 review).
