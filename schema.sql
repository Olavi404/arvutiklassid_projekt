-- ============================================================
-- Arvutiklasside kasutuse andmebaas
-- Projekt: TAK25
-- Fail genereeritud CASE-protsessi tulemusena (vt erd.dbml / erd_crowsfoot.svg / uml_class.svg)
-- Andmebaasimootor: MariaDB / MySQL
-- ============================================================

CREATE DATABASE IF NOT EXISTS arvutiklassid
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE arvutiklassid;

-- ------------------------------------------------------------
-- Puhastus (korduvkäivitamise jaoks)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS booking_participant;
DROP TABLE IF EXISTS booking;
DROP TABLE IF EXISTS lesson_type;
DROP TABLE IF EXISTS user_or_group;
DROP TABLE IF EXISTS classroom;

-- ------------------------------------------------------------
-- 1) classroom (arvutiklass)
-- ------------------------------------------------------------
CREATE TABLE classroom (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    name             VARCHAR(50)  NOT NULL UNIQUE,      -- nt "A-101"
    location         VARCHAR(100),                      -- nt "Peahoone, 2. korrus"
    capacity         INT NOT NULL,                       -- max istekohti
    computers_count  INT NOT NULL,                       -- arvutite arv klassis
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_classroom_capacity CHECK (capacity > 0),
    CONSTRAINT chk_classroom_computers CHECK (computers_count >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2) user_or_group (õpetaja / grupp)
-- ------------------------------------------------------------
CREATE TABLE user_or_group (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,                  -- nt "Jaan Tamm" või "TAK25"
    type        ENUM('teacher','group') NOT NULL,
    email       VARCHAR(150) UNIQUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3) lesson_type (tunni tüüp - lookup tabel)
-- ------------------------------------------------------------
CREATE TABLE lesson_type (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,             -- nt "loeng", "praktikum"
    description VARCHAR(255)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4) booking (broneering)
--    1:N seosed: classroom -> booking, user_or_group -> booking (organizer),
--                 lesson_type -> booking
-- ------------------------------------------------------------
CREATE TABLE booking (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    classroom_id        INT NOT NULL,
    organizer_id        INT NOT NULL,
    lesson_type_id      INT NOT NULL,
    booking_date        DATE NOT NULL,
    start_time          TIME NOT NULL,
    end_time            TIME NOT NULL,
    participants_count  INT NOT NULL DEFAULT 0,
    status              ENUM('planned','completed','cancelled') NOT NULL DEFAULT 'planned',
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_booking_classroom
        FOREIGN KEY (classroom_id) REFERENCES classroom(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_booking_organizer
        FOREIGN KEY (organizer_id) REFERENCES user_or_group(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_booking_lesson_type
        FOREIGN KEY (lesson_type_id) REFERENCES lesson_type(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Ärireegel 1: broneeringu lõpp peab olema hilisem kui algus (CHECK)
    CONSTRAINT chk_booking_time CHECK (end_time > start_time),
    -- Ärireegel 2: osalejate arv ei saa olla negatiivne (CHECK)
    CONSTRAINT chk_booking_participants CHECK (participants_count >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_booking_classroom_date ON booking(classroom_id, booking_date);
CREATE INDEX idx_booking_organizer ON booking(organizer_id);

-- ------------------------------------------------------------
-- 5) booking_participant (vahetabel N..M seose jaoks:
--    üks broneering võib kaasata mitu gruppi/õpetajat lisaks korraldajale,
--    üks grupp/õpetaja võib osaleda mitmes broneeringus)
-- ------------------------------------------------------------
CREATE TABLE booking_participant (
    booking_id      INT NOT NULL,
    participant_id  INT NOT NULL,
    PRIMARY KEY (booking_id, participant_id),
    CONSTRAINT fk_bp_booking
        FOREIGN KEY (booking_id) REFERENCES booking(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bp_participant
        FOREIGN KEY (participant_id) REFERENCES user_or_group(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Ärireegel 3: osalejate arv ei tohi ületada klassi mahtuvust (TRIGGER)
-- ------------------------------------------------------------
DELIMITER //
CREATE TRIGGER trg_booking_capacity_insert
BEFORE INSERT ON booking
FOR EACH ROW
BEGIN
    DECLARE room_capacity INT;
    SELECT capacity INTO room_capacity FROM classroom WHERE id = NEW.classroom_id;
    IF NEW.participants_count > room_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Osalejate arv ületab klassi mahtuvuse (capacity)';
    END IF;
END//

CREATE TRIGGER trg_booking_capacity_update
BEFORE UPDATE ON booking
FOR EACH ROW
BEGIN
    DECLARE room_capacity INT;
    SELECT capacity INTO room_capacity FROM classroom WHERE id = NEW.classroom_id;
    IF NEW.participants_count > room_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Osalejate arv ületab klassi mahtuvuse (capacity)';
    END IF;
END//
DELIMITER ;

-- ------------------------------------------------------------
-- Ärireegel 4 (rakenduse tasemel, vt app/server.js funktsioon
-- checkOverlap()): sama klassi kaks broneeringut ei tohi samal
-- kuupäeval kattuda ajaliselt. Ei ole lahendatav puhta CHECK/trigger
-- lahendusega ilma keerulise korrelatsioonita, seega valideeritakse
-- rakenduse API kihis enne INSERT/UPDATE käske.
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Statistikavaade: klasside kasutus tundides nädalas
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_weekly_classroom_usage AS
SELECT
    c.id                                AS classroom_id,
    c.name                              AS classroom_name,
    YEARWEEK(b.booking_date, 3)         AS year_week,
    COUNT(b.id)                         AS bookings_count,
    ROUND(SUM(TIME_TO_SEC(TIMEDIFF(b.end_time, b.start_time)))/3600, 2) AS hours_used
FROM classroom c
JOIN booking b ON b.classroom_id = c.id
WHERE b.status <> 'cancelled'
GROUP BY c.id, c.name, YEARWEEK(b.booking_date, 3);

-- Top 5 kõige kasutatumad klassid (koguaeg)
CREATE OR REPLACE VIEW v_top_classrooms AS
SELECT
    c.id AS classroom_id,
    c.name AS classroom_name,
    COUNT(b.id) AS total_bookings,
    ROUND(SUM(TIME_TO_SEC(TIMEDIFF(b.end_time, b.start_time)))/3600, 2) AS total_hours
FROM classroom c
JOIN booking b ON b.classroom_id = c.id
WHERE b.status <> 'cancelled'
GROUP BY c.id, c.name
ORDER BY total_hours DESC
LIMIT 5;
