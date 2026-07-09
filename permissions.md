# Õigused – kasutajad, rollid ja testimine

## Loodud rollid ja kasutajad

| Kasutaja | Roll | Õigused | Parool |
|----------|------|---------|--------|
| `admin_user` | `role_admin` | `ALL PRIVILEGES` andmebaasil `arvutiklassid` | `admin_pass_123` |
| `viewer_user` | `role_viewer` | ainult `SELECT` | `viewer_pass_123` |

Lisaks kasutab rakendus eraldi kontot `app_user` (`SELECT, INSERT, UPDATE, DELETE`),
mida kasutatakse veebirakenduse igapäevases töös.

## GRANT ja REVOKE

Skript `permissions.sql`:
1. loob kaks rolli (`role_admin`, `role_viewer`) ja annab neile õigused (`GRANT`);
2. loob kaks kasutajat ja määrab neile rollid (`GRANT role TO user`);
3. seab vaikerolli (`SET DEFAULT ROLE`), et roll aktiveeruks kohe sisselogimisel;
4. demonstreerib `REVOKE`-i: annab `viewer_user`-ile ajutiselt `INSERT` õiguse
   `booking` tabelile ja võtab selle kohe tagasi, et viewer jääks ainult-loku'ks.

## Kuidas testisin

```bash
# 1) Viewer saab lugeda (SELECT õnnestub):
mysql -u viewer_user -pviewer_pass_123 arvutiklassid -e "SELECT COUNT(*) FROM booking;"
#   -> tagastab 15

# 2) Viewer EI saa kirjutada (INSERT nurjub õiguse puudumise tõttu):
mysql -u viewer_user -pviewer_pass_123 arvutiklassid -e "INSERT INTO lesson_type (name) VALUES ('hack');"
#   -> ERROR 1142: INSERT command denied to user 'viewer_user'

# 3) Admin saab kirjutada (INSERT õnnestub):
mysql -u admin_user -padmin_pass_123 arvutiklassid -e "INSERT INTO lesson_type (name) VALUES ('test_admin');"
#   -> õnnestub
```

Kõik kolm testi käitusid ootuspäraselt: viewer on ainult-loku, admin täisõigustega.

## Märkus mootori kohta

Kasutasin MariaDB-d (MySQL-ühilduv), kus rollid ja `GRANT`/`REVOKE` toimivad
klassikaliselt serveritasandil. SQLite seda ei toeta, mistõttu see valik oli
teadlik just õiguste alamteema tõttu.
