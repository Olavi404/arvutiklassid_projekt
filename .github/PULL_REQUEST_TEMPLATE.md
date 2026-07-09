<!--
Enne PR-i esitamist: kinnita, et alljärgnev kontrollnimekiri (vt ka AGENTS.md
peatükk 9) on läbitud. See kehtib nii inimarendajale kui AI-agendile.
-->

## Mida see PR muudab

<!-- Lühike kirjeldus, mis muutus ja miks. -->

## Kontrollnimekiri

- [ ] `npm test` (kaustast `app/`) on käivitatud ja kõik testid läbivad.
- [ ] `npm run lint` (kaustast `app/`) on käivitatud ja lint ei anna vigu.
- [ ] Uus funktsionaalsus sisaldab teste; bugifix sisaldab regressioonitesti.
- [ ] Ühtegi mitteseotud faili pole muudetud (vt AGENTS.md peatükk 6, ulatuse piiramine).
- [ ] Ühtegi saladust (parool, API-võti, token) pole lisatud.
- [ ] Kui muudeti andmebaasi skeemi (`schema.sql`) või õigusi (`permissions.sql`),
      on see selgesõnaliselt välja toodud ja käsitsi testitud käivitatud
      MariaDB instantsi vastu.
- [ ] CI (GitHub Actions) on selle PR-i peal roheline.

## Seotud probleem / kontekst (valikuline)

<!-- Nt viide teemale, ülesandele või õppeaine nõudele. -->
