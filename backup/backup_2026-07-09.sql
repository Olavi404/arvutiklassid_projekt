/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.14-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: arvutiklassid
-- ------------------------------------------------------
-- Server version	10.11.14-MariaDB-0ubuntu0.24.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `arvutiklassid`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `arvutiklassid` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `arvutiklassid`;

--
-- Table structure for table `booking`
--

DROP TABLE IF EXISTS `booking`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `booking` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `classroom_id` int(11) NOT NULL,
  `organizer_id` int(11) NOT NULL,
  `lesson_type_id` int(11) NOT NULL,
  `booking_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `participants_count` int(11) NOT NULL DEFAULT 0,
  `status` enum('planned','completed','cancelled') NOT NULL DEFAULT 'planned',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_booking_lesson_type` (`lesson_type_id`),
  KEY `idx_booking_classroom_date` (`classroom_id`,`booking_date`),
  KEY `idx_booking_organizer` (`organizer_id`),
  CONSTRAINT `fk_booking_classroom` FOREIGN KEY (`classroom_id`) REFERENCES `classroom` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_booking_lesson_type` FOREIGN KEY (`lesson_type_id`) REFERENCES `lesson_type` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_booking_organizer` FOREIGN KEY (`organizer_id`) REFERENCES `user_or_group` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `chk_booking_time` CHECK (`end_time` > `start_time`),
  CONSTRAINT `chk_booking_participants` CHECK (`participants_count` >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `booking`
--

LOCK TABLES `booking` WRITE;
/*!40000 ALTER TABLE `booking` DISABLE KEYS */;
INSERT INTO `booking` VALUES
(1,1,1,1,'2026-01-12','09:00:00','10:30:00',22,'completed','2026-07-09 00:09:06'),
(2,1,2,2,'2026-01-12','11:00:00','12:30:00',18,'completed','2026-07-09 00:09:06'),
(3,3,3,1,'2026-01-13','08:15:00','09:45:00',28,'completed','2026-07-09 00:09:06'),
(4,4,4,3,'2026-01-14','10:00:00','12:00:00',16,'planned','2026-07-09 00:09:06'),
(5,1,6,4,'2026-01-15','14:00:00','16:00:00',20,'completed','2026-07-09 00:09:06'),
(6,5,5,2,'2026-01-15','09:00:00','10:30:00',15,'completed','2026-07-09 00:09:06'),
(7,3,1,1,'2026-01-19','09:00:00','10:30:00',25,'completed','2026-07-09 00:09:06'),
(8,1,2,2,'2026-01-19','11:00:00','13:00:00',21,'completed','2026-07-09 00:09:06'),
(9,6,4,1,'2026-01-20','12:00:00','13:30:00',22,'completed','2026-07-09 00:09:06'),
(10,1,3,1,'2026-01-21','08:15:00','09:45:00',23,'completed','2026-07-09 00:09:06'),
(11,7,5,5,'2026-01-21','15:00:00','16:00:00',8,'completed','2026-07-09 00:09:06'),
(12,3,7,4,'2026-01-22','10:00:00','12:30:00',26,'completed','2026-07-09 00:09:06'),
(13,2,1,2,'2026-01-26','09:00:00','11:00:00',19,'completed','2026-07-09 00:09:06'),
(14,1,2,1,'2026-01-26','12:00:00','13:30:00',24,'completed','2026-07-09 00:09:06'),
(15,5,4,3,'2026-01-28','10:00:00','12:00:00',18,'planned','2026-07-09 00:09:06');
/*!40000 ALTER TABLE `booking` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_booking_capacity_insert
BEFORE INSERT ON booking
FOR EACH ROW
BEGIN
    DECLARE room_capacity INT;
    SELECT capacity INTO room_capacity FROM classroom WHERE id = NEW.classroom_id;
    IF NEW.participants_count > room_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Osalejate arv ületab klassi mahtuvuse (capacity)';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_booking_capacity_update
BEFORE UPDATE ON booking
FOR EACH ROW
BEGIN
    DECLARE room_capacity INT;
    SELECT capacity INTO room_capacity FROM classroom WHERE id = NEW.classroom_id;
    IF NEW.participants_count > room_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Osalejate arv ületab klassi mahtuvuse (capacity)';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `booking_participant`
--

DROP TABLE IF EXISTS `booking_participant`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `booking_participant` (
  `booking_id` int(11) NOT NULL,
  `participant_id` int(11) NOT NULL,
  PRIMARY KEY (`booking_id`,`participant_id`),
  KEY `fk_bp_participant` (`participant_id`),
  CONSTRAINT `fk_bp_booking` FOREIGN KEY (`booking_id`) REFERENCES `booking` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_bp_participant` FOREIGN KEY (`participant_id`) REFERENCES `user_or_group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `booking_participant`
--

LOCK TABLES `booking_participant` WRITE;
/*!40000 ALTER TABLE `booking_participant` DISABLE KEYS */;
INSERT INTO `booking_participant` VALUES
(1,6),
(3,7),
(3,8);
/*!40000 ALTER TABLE `booking_participant` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `classroom`
--

DROP TABLE IF EXISTS `classroom`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `classroom` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `location` varchar(100) DEFAULT NULL,
  `capacity` int(11) NOT NULL,
  `computers_count` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  CONSTRAINT `chk_classroom_capacity` CHECK (`capacity` > 0),
  CONSTRAINT `chk_classroom_computers` CHECK (`computers_count` >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `classroom`
--

LOCK TABLES `classroom` WRITE;
/*!40000 ALTER TABLE `classroom` DISABLE KEYS */;
INSERT INTO `classroom` VALUES
(1,'A-101','Peahoone 1. korrus',24,24,'2026-07-09 00:09:06'),
(2,'A-102','Peahoone 1. korrus',20,20,'2026-07-09 00:09:06'),
(3,'B-201','B-korpus 2. korrus',30,28,'2026-07-09 00:09:06'),
(4,'B-202','B-korpus 2. korrus',16,16,'2026-07-09 00:09:06'),
(5,'C-105','C-korpus 1. korrus',18,18,'2026-07-09 00:09:06'),
(6,'C-106','C-korpus 1. korrus',22,22,'2026-07-09 00:09:06'),
(7,'D-301','D-korpus 3. korrus',12,12,'2026-07-09 00:09:06');
/*!40000 ALTER TABLE `classroom` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lesson_type`
--

DROP TABLE IF EXISTS `lesson_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `lesson_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lesson_type`
--

LOCK TABLES `lesson_type` WRITE;
/*!40000 ALTER TABLE `lesson_type` DISABLE KEYS */;
INSERT INTO `lesson_type` VALUES
(1,'loeng',NULL),
(2,'praktikum',NULL),
(3,'eksam',NULL),
(4,'iseseisev töö',NULL),
(5,'konsultatsioon',NULL);
/*!40000 ALTER TABLE `lesson_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_or_group`
--

DROP TABLE IF EXISTS `user_or_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_or_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `type` enum('teacher','group') NOT NULL,
  `email` varchar(150) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_or_group`
--

LOCK TABLES `user_or_group` WRITE;
/*!40000 ALTER TABLE `user_or_group` DISABLE KEYS */;
INSERT INTO `user_or_group` VALUES
(1,'Jaan Tamm','teacher','jaan.tamm@kool.ee','2026-07-09 00:09:06'),
(2,'Mari Kask','teacher','mari.kask@kool.ee','2026-07-09 00:09:06'),
(3,'Peeter Saar','teacher','peeter.saar@kool.ee','2026-07-09 00:09:06'),
(4,'Liis Mägi','teacher','liis.magi@kool.ee','2026-07-09 00:09:06'),
(5,'Toomas Rebane','teacher','toomas.rebane@kool.ee','2026-07-09 00:09:06'),
(6,'TAK25','group','tak25@kool.ee','2026-07-09 00:09:06'),
(7,'TAK24','group','tak24@kool.ee','2026-07-09 00:09:06'),
(8,'RIF25','group','rif25@kool.ee','2026-07-09 00:09:06'),
(9,'IT23','group','it23@kool.ee','2026-07-09 00:09:06');
/*!40000 ALTER TABLE `user_or_group` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `v_top_classrooms`
--

DROP TABLE IF EXISTS `v_top_classrooms`;
/*!50001 DROP VIEW IF EXISTS `v_top_classrooms`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v_top_classrooms` AS SELECT
 1 AS `classroom_id`,
  1 AS `classroom_name`,
  1 AS `total_bookings`,
  1 AS `total_hours` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_weekly_classroom_usage`
--

DROP TABLE IF EXISTS `v_weekly_classroom_usage`;
/*!50001 DROP VIEW IF EXISTS `v_weekly_classroom_usage`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v_weekly_classroom_usage` AS SELECT
 1 AS `classroom_id`,
  1 AS `classroom_name`,
  1 AS `year_week`,
  1 AS `bookings_count`,
  1 AS `hours_used` */;
SET character_set_client = @saved_cs_client;

--
-- Dumping routines for database 'arvutiklassid'
--

--
-- Current Database: `arvutiklassid`
--

USE `arvutiklassid`;

--
-- Final view structure for view `v_top_classrooms`
--

/*!50001 DROP VIEW IF EXISTS `v_top_classrooms`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_top_classrooms` AS select `c`.`id` AS `classroom_id`,`c`.`name` AS `classroom_name`,count(`b`.`id`) AS `total_bookings`,round(sum(time_to_sec(timediff(`b`.`end_time`,`b`.`start_time`))) / 3600,2) AS `total_hours` from (`classroom` `c` join `booking` `b` on(`b`.`classroom_id` = `c`.`id`)) where `b`.`status` <> 'cancelled' group by `c`.`id`,`c`.`name` order by round(sum(time_to_sec(timediff(`b`.`end_time`,`b`.`start_time`))) / 3600,2) desc limit 5 */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_weekly_classroom_usage`
--

/*!50001 DROP VIEW IF EXISTS `v_weekly_classroom_usage`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_weekly_classroom_usage` AS select `c`.`id` AS `classroom_id`,`c`.`name` AS `classroom_name`,yearweek(`b`.`booking_date`,3) AS `year_week`,count(`b`.`id`) AS `bookings_count`,round(sum(time_to_sec(timediff(`b`.`end_time`,`b`.`start_time`))) / 3600,2) AS `hours_used` from (`classroom` `c` join `booking` `b` on(`b`.`classroom_id` = `c`.`id`)) where `b`.`status` <> 'cancelled' group by `c`.`id`,`c`.`name`,yearweek(`b`.`booking_date`,3) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-09  0:09:26
