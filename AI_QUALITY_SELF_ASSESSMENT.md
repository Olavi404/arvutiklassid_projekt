# Enesehinnang (5–10 lauset)

Kõige kasulikum reegel oli nõue eraldada DB-sõltumatud ärireeglid omaette
testitavasse moodulisse (`validation.js`) — see sundis kohe algusest peale
mõtlema, kuidas testida loogikat ilma käivitatud andmebaasita, mitte lükata
seda "hiljem" kategooriasse. Samuti oli kasulik kontrollnimekiri, mis nõuab
testide ja lindi käivitamist enne töö valmisolevaks märkimist — see paljastas
kohe, et `node --test test/` süntaks ei tööta ES-moodulite projektis oodatud
viisil ja vajas glob-mustrit (`test/*.test.js`).

Suurim allesjäänud risk on see, et ärireegli "ajaline kattumine" (`checkOverlap`)
jääb endiselt katmata automaattestidega, kuna see sõltub otseselt käivitatud
MariaDB instantsist — praegu on see kontrollitud ainult käsitsi ja koodiülevaates,
mitte CI-s. Samuti pole veel seadistatud tehnilist kaitset (CI workflow, branch
protection, PR template), mistõttu reeglite fail iseenesest ei taga, et keegi
ei tee otsest commit'i `main` harusse.

Järgmises versioonis lisaksin integratsioonitestid `checkOverlap` funktsioonile
kas testandmebaasi (nt Docker-konteineris käivitatav MariaDB) või mock'itud
`pool.query`-ga. GitHub Actions CI workflow on nüüd lisatud
(`.github/workflows/ci.yml`) ja käivitab `npm ci`, lindi ning testid
automaatselt — järgmine samm oleks seadistada GitHubi repo seadetes ka
branch protection reegel, mis nõuab rohelist CI-d enne `main` harusse
merge'imist, ning lisada PR template.
