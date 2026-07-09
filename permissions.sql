-- ============================================================
-- permissions.sql — kasutajad, rollid ja õigused
-- Andmebaasimootor: MariaDB / MySQL
-- Käivitamine:  mysql -u root < permissions.sql
-- ============================================================

USE arvutiklassid;

-- ------------------------------------------------------------
-- Puhastus (korduvkäivitamise jaoks)
-- ------------------------------------------------------------
DROP USER IF EXISTS 'admin_user'@'%';
DROP USER IF EXISTS 'viewer_user'@'%';
DROP ROLE IF EXISTS 'role_admin';
DROP ROLE IF EXISTS 'role_viewer';

-- ------------------------------------------------------------
-- 1) ROLLID
-- ------------------------------------------------------------
CREATE ROLE 'role_admin';
CREATE ROLE 'role_viewer';

-- admin roll: täisõigused kogu andmebaasile
GRANT ALL PRIVILEGES ON arvutiklassid.* TO 'role_admin';

-- viewer roll: ainult lugemine (SELECT)
GRANT SELECT ON arvutiklassid.* TO 'role_viewer';

-- ------------------------------------------------------------
-- 2) KASUTAJAD
-- ------------------------------------------------------------
CREATE USER 'admin_user'@'%'  IDENTIFIED BY 'admin_pass_123';
CREATE USER 'viewer_user'@'%' IDENTIFIED BY 'viewer_pass_123';

-- ------------------------------------------------------------
-- 3) ROLLIDE MÄÄRAMINE KASUTAJATELE
-- ------------------------------------------------------------
GRANT 'role_admin'  TO 'admin_user'@'%';
GRANT 'role_viewer' TO 'viewer_user'@'%';

-- Rollid aktiveeruvad automaatselt sisselogimisel
SET DEFAULT ROLE 'role_admin'  FOR 'admin_user'@'%';
SET DEFAULT ROLE 'role_viewer' FOR 'viewer_user'@'%';

-- ------------------------------------------------------------
-- 4) OTSEÕIGUSE NÄIDE + REVOKE
--    Anname viewerile ajutiselt õiguse ka statistikavaatele
--    otse (lisaks rollile), seejärel REVOKE näitab õiguse
--    eemaldamist.
-- ------------------------------------------------------------
-- Anname viewer_user'ile ajutiselt INSERT õiguse booking tabelile
GRANT INSERT ON arvutiklassid.booking TO 'viewer_user'@'%';

-- REVOKE: võtame selle õiguse tagasi (viewer peab jääma ainult-loku'ks)
REVOKE INSERT ON arvutiklassid.booking FROM 'viewer_user'@'%';

-- ------------------------------------------------------------
-- 5) RAKENDUSE KASUTAJA
--    Veebirakendus kasutab eraldi kontot, millel on CRUD-õigused
--    (SELECT, INSERT, UPDATE, DELETE), aga mitte administratiivseid
--    õigusi (nt DROP, GRANT).
-- ------------------------------------------------------------
DROP USER IF EXISTS 'app_user'@'%';
CREATE USER 'app_user'@'%' IDENTIFIED BY 'app_pass_123';
GRANT SELECT, INSERT, UPDATE, DELETE ON arvutiklassid.* TO 'app_user'@'%';

FLUSH PRIVILEGES;

-- ------------------------------------------------------------
-- Kontroll: kuva antud õigused
-- ------------------------------------------------------------
SHOW GRANTS FOR 'admin_user'@'%';
SHOW GRANTS FOR 'viewer_user'@'%';
SHOW GRANTS FOR 'role_admin';
SHOW GRANTS FOR 'role_viewer';
SHOW GRANTS FOR 'app_user'@'%';
