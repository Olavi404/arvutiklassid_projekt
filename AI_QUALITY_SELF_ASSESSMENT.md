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
mitte CI-s.

Järgmises versioonis lisaksin integratsioonitestid `checkOverlap` funktsioonile
kas testandmebaasi (nt Docker-konteineris käivitatav MariaDB) või mock'itud
`pool.query`-ga. GitHub Actions CI workflow (`.github/workflows/ci.yml`),
PR template ja branch protection `master` harul (nõuab rohelist CI-d ja
keelab otsese push'i/force push'i, ka repo omanikule) on nüüd kõik
seadistatud, seega reeglite fail ei ole enam ainus kaitse — tehniline
tugi GitHubi tasandil on olemas.
