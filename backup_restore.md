# Varundamine ja taastamine

## 5.1. Varundamine

Varukoopia tehti `mysqldump` tööriistaga, kaasa arvatud triggerid ja protseduurid:

```bash
mysqldump -u root --databases arvutiklassid --routines --triggers \
  > backup/backup_$(date +%Y-%m-%d).sql
```

Tulemus: `backup/backup_2026-07-09.sql` (sisaldab kogu skeemi + andmed + triggerid + vaated).

## 5.2. Taastamine

Testisin taastamist kontrollitud stsenaariumiga: kustutasin `booking` ja
`booking_participant` tabelid ning taastasin need backupist.

```bash
# 1) Kustuta tabelid (kontrollitud test)
mysql -u root arvutiklassid -e \
  "SET FOREIGN_KEY_CHECKS=0; DROP TABLE booking_participant; DROP TABLE booking; SET FOREIGN_KEY_CHECKS=1;"

# 2) Taasta backupist
mysql -u root < backup/backup_2026-07-09.sql
```

## Tõendus (enne / pärast)

Täielik logi on failis `backup/restore_proof.txt`. Kokkuvõte:

| Etapp | `booking` ridu | Tabelid olemas? |
|-------|----------------|------------------|
| **Enne** | 15 | jah |
| **Pärast DROP-i** | — | ei (`booking` ja `booking_participant` kadunud tabelite loendist) |
| **Pärast taastamist** | 15 | jah (+ 3 rida `booking_participant`-is) |

Andmed tulid täielikult tagasi — nii broneeringud (15) kui ka N..M
vahetabeli read (3) taastusid identselt.
