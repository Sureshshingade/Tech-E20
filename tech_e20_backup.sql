-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: localhost    Database: fuel_station_db
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `attendance`
--

DROP TABLE IF EXISTS `attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendance` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `attendance_date` date NOT NULL,
  `template_id` int NOT NULL,
  `status` enum('PRESENT','ABSENT','LEAVE') NOT NULL,
  `recorded_by` int NOT NULL,
  `correction_reason` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_attendance_person_shift` (`user_id`,`attendance_date`,`template_id`),
  KEY `idx_attendance_date` (`attendance_date`),
  KEY `fk_attendance_template` (`template_id`),
  KEY `fk_attendance_recorder` (`recorded_by`),
  CONSTRAINT `fk_attendance_recorder` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_attendance_template` FOREIGN KEY (`template_id`) REFERENCES `shift_templates` (`id`),
  CONSTRAINT `fk_attendance_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `attendance`
--

LOCK TABLES `attendance` WRITE;
/*!40000 ALTER TABLE `attendance` DISABLE KEYS */;
INSERT INTO `attendance` VALUES (1,2,'2026-10-13',1,'PRESENT',1,NULL,'2026-10-13 10:36:22','2026-10-13 10:36:22'),(2,6,'2026-10-13',1,'PRESENT',1,NULL,'2026-10-13 10:36:27','2026-10-13 10:36:27'),(3,10,'2026-10-13',1,'PRESENT',1,NULL,'2026-10-13 10:36:29','2026-10-13 10:36:29'),(4,8,'2026-10-13',1,'ABSENT',1,NULL,'2026-10-13 10:36:33','2026-10-13 10:36:33'),(5,4,'2026-10-13',1,'ABSENT',1,NULL,'2026-10-13 10:36:37','2026-10-13 10:37:17'),(6,12,'2026-10-13',2,'PRESENT',1,NULL,'2026-10-13 10:36:42','2026-10-13 10:36:42'),(7,3,'2026-10-13',2,'LEAVE',1,NULL,'2026-10-13 10:36:46','2026-10-13 10:36:46'),(8,5,'2026-10-13',2,'ABSENT',1,NULL,'2026-10-13 10:36:50','2026-10-13 10:36:50'),(9,7,'2026-10-13',2,'LEAVE',1,NULL,'2026-10-13 10:36:54','2026-10-13 10:36:54'),(10,13,'2026-10-13',1,'LEAVE',1,NULL,'2026-10-13 10:39:21','2026-10-13 10:39:21'),(11,14,'2026-10-13',2,'PRESENT',1,NULL,'2026-10-13 10:44:56','2026-10-13 10:44:56');
/*!40000 ALTER TABLE `attendance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `audit_logs`
--

DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `actor_user_id` int DEFAULT NULL,
  `action` varchar(80) NOT NULL,
  `entity_type` varchar(80) NOT NULL,
  `entity_id` bigint DEFAULT NULL,
  `details` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_actor_created` (`actor_user_id`,`created_at`),
  KEY `idx_audit_entity` (`entity_type`,`entity_id`),
  CONSTRAINT `fk_audit_actor` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=103 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_logs`
--

LOCK TABLES `audit_logs` WRITE;
/*!40000 ALTER TABLE `audit_logs` DISABLE KEYS */;
INSERT INTO `audit_logs` VALUES (1,1,'OWNER_CREATED','user',1,'Initial owner account created','2026-10-12 17:45:14'),(2,1,'AUTH_LOGIN','user',1,NULL,'2026-10-12 17:48:59'),(3,1,'AUTH_LOGIN','user',1,NULL,'2026-10-12 17:52:48'),(4,1,'USER_CREATED','user',2,'Created manager account','2026-10-12 17:54:28'),(5,1,'USER_CREATED','user',3,'Created employee account','2026-10-12 17:57:00'),(6,1,'AUTH_LOGIN','user',1,NULL,'2026-10-13 07:55:15'),(7,1,'AUTH_LOGOUT','user',1,NULL,'2026-10-13 07:55:58'),(8,2,'AUTH_LOGIN','user',2,NULL,'2026-10-13 07:56:08'),(9,2,'AUTH_LOGOUT','user',2,NULL,'2026-10-13 07:56:59'),(10,3,'AUTH_LOGIN','user',3,NULL,'2026-10-13 07:57:03'),(11,1,'AUTH_LOGIN','user',1,NULL,'2026-10-13 08:50:42'),(12,1,'DEMO_TANKER_DELIVERY_CREATED','tanker_delivery',1,'Demo delivery created for 13-10-2026','2026-10-13 08:55:15'),(13,1,'DEMO_TANKER_DELIVERY_CREATED','tanker_delivery',2,'Demo delivery created for 13-10-2026','2026-10-13 08:55:15'),(14,1,'USER_UPDATED','user',2,'Updated: full_name, email, role, is_active','2026-10-13 09:01:43'),(15,1,'USER_UPDATED','user',1,'{\"changed\": [\"username\", \"full_name\", \"email\", \"password\"], \"before\": {\"username\": \"owner\", \"full_name\": \"FuelGuard Owner\", \"email\": null}, \"after\": {\"username\": \"suresh11\", \"full_name\": \"SURESH BAJRANG SHINGADE\", \"email\": \"sureshshingade38700@gmail.com\"}}','2026-10-13 09:28:52'),(16,1,'AUTH_LOGOUT','user',1,NULL,'2026-10-13 09:29:13'),(17,1,'AUTH_LOGIN','user',1,NULL,'2026-10-13 09:29:34'),(18,1,'STATION_NAME_UPDATED','station_settings',1,'{\"before\": \"My Petrol Pump\", \"after\": \"Sharda Petroleum\"}','2026-10-13 09:30:47'),(19,1,'STATION_NAME_UPDATED','station_settings',1,'{\"before\": \"Sharda Petroleum\", \"after\": \"Sharda Petroleum\"}','2026-10-13 09:31:23'),(20,1,'USER_UPDATED','user',3,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"password\"], \"before\": {\"username\": \"prakash\", \"full_name\": \"petrol prakash\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1}, \"after\": {\"username\": \"abhi\", \"full_name\": \"abhi\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true}}','2026-10-13 09:49:44'),(21,1,'STATION_NAME_UPDATED','station_settings',1,'{\"before\": \"Sharda Petroleum\", \"after\": \"Sharda&Alianka Petroleum\"}','2026-10-13 09:51:29'),(22,1,'USER_CREATED','user',4,'Created employee account','2026-10-13 09:52:15'),(23,1,'USER_CREATED','user',5,'Created employee account','2026-10-13 09:52:42'),(24,1,'USER_CREATED','user',6,'Created employee account','2026-10-13 09:53:03'),(25,1,'USER_CREATED','user',7,'Created employee account','2026-10-13 09:53:37'),(26,1,'USER_UPDATED','user',2,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"password\"], \"before\": {\"username\": \"lolraju\", \"full_name\": \"(M)Loyal_raju\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": 1}, \"after\": {\"username\": \"nikhil\", \"full_name\": \"(M)Nikhil_Sir\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": true}}','2026-10-13 09:54:45'),(27,1,'USER_CREATED','user',8,'Created employee account','2026-10-13 09:55:18'),(28,1,'USER_CREATED','user',9,'Created employee account','2026-10-13 09:56:13'),(29,1,'USER_CREATED','user',10,'Created employee account','2026-10-13 09:57:44'),(30,1,'USER_CREATED','user',11,'Created employee account','2026-10-13 09:58:44'),(31,1,'USER_UPDATED','user',11,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\"], \"before\": {\"username\": \"fychetan\", \"full_name\": \"chetanFY\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1}, \"after\": {\"username\": \"fychetan\", \"full_name\": \"chetanFY\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": false}}','2026-10-13 10:03:19'),(32,1,'AUTH_LOGOUT','user',1,NULL,'2026-10-13 10:30:25'),(33,1,'AUTH_LOGIN','user',1,NULL,'2026-10-13 10:30:40'),(34,1,'USER_UPDATED','user',2,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"nikhil\", \"full_name\": \"(M)Nikhil_Sir\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": 1, \"default_shift\": null}, \"after\": {\"username\": \"nikhil\", \"full_name\": \"(M)Nikhil_Sir\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": true, \"default_shift\": \"Morning\"}}','2026-10-13 10:31:23'),(35,1,'USER_UPDATED','user',3,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"abhi\", \"full_name\": \"abhi\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": null}, \"after\": {\"username\": \"abhi\", \"full_name\": \"abhi\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-13 10:31:40'),(36,1,'USER_UPDATED','user',5,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"chetan\", \"full_name\": \"chetan_bhai\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": null}, \"after\": {\"username\": \"chetan\", \"full_name\": \"chetan_bhai\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-13 10:31:52'),(37,1,'USER_UPDATED','user',9,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"jayram\", \"full_name\": \"jayram\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": null}, \"after\": {\"username\": \"jayram\", \"full_name\": \"jayram\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": false, \"default_shift\": \"Morning\"}}','2026-10-13 10:32:06'),(38,1,'USER_UPDATED','user',6,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"manohar\", \"full_name\": \"manohar\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": null}, \"after\": {\"username\": \"manohar\", \"full_name\": \"manohar\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Morning\"}}','2026-10-13 10:32:17'),(39,1,'USER_UPDATED','user',10,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"omkar\", \"full_name\": \"omkar\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": null}, \"after\": {\"username\": \"omkar\", \"full_name\": \"omkar\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Morning\"}}','2026-10-13 10:32:28'),(40,1,'USER_UPDATED','user',8,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"satyam\", \"full_name\": \"satyam\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": null}, \"after\": {\"username\": \"satyam\", \"full_name\": \"satyam\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Morning\"}}','2026-10-13 10:32:47'),(41,1,'USER_UPDATED','user',7,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"vinit\", \"full_name\": \"vinit\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": null}, \"after\": {\"username\": \"vinit\", \"full_name\": \"vinit\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-13 10:32:56'),(42,1,'USER_UPDATED','user',4,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"yash\", \"full_name\": \"yash\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": null}, \"after\": {\"username\": \"yash\", \"full_name\": \"yash\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Morning\"}}','2026-10-13 10:33:06'),(43,1,'USER_CREATED','user',12,'Created manager account','2026-10-13 10:34:43'),(44,1,'USER_UPDATED','user',12,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"password\", \"default_shift\"], \"before\": {\"username\": \"vijaya_mam\", \"full_name\": \"vijaya_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": 1, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"vijaya_mam\", \"full_name\": \"vijaya_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-13 10:35:07'),(45,1,'USER_UPDATED','user',12,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"vijaya_mam\", \"full_name\": \"vijaya_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": 1, \"default_shift\": \"Evening\"}, \"after\": {\"username\": \"vijaya_mam\", \"full_name\": \"(M)vijaya_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-13 10:35:45'),(46,1,'ATTENDANCE_RECORDED','attendance',1,'{\"staff\": \"(M)Nikhil_Sir\", \"date\": \"2026-10-13\", \"shift\": \"Morning\", \"after\": {\"status\": \"PRESENT\", \"reason\": null}}','2026-10-13 10:36:22'),(47,1,'ATTENDANCE_RECORDED','attendance',2,'{\"staff\": \"manohar\", \"date\": \"2026-10-13\", \"shift\": \"Morning\", \"after\": {\"status\": \"PRESENT\", \"reason\": null}}','2026-10-13 10:36:27'),(48,1,'ATTENDANCE_RECORDED','attendance',3,'{\"staff\": \"omkar\", \"date\": \"2026-10-13\", \"shift\": \"Morning\", \"after\": {\"status\": \"PRESENT\", \"reason\": null}}','2026-10-13 10:36:29'),(49,1,'ATTENDANCE_RECORDED','attendance',4,'{\"staff\": \"satyam\", \"date\": \"2026-10-13\", \"shift\": \"Morning\", \"after\": {\"status\": \"ABSENT\", \"reason\": null}}','2026-10-13 10:36:33'),(50,1,'ATTENDANCE_RECORDED','attendance',5,'{\"staff\": \"yash\", \"date\": \"2026-10-13\", \"shift\": \"Morning\", \"after\": {\"status\": \"LEAVE\", \"reason\": null}}','2026-10-13 10:36:37'),(51,1,'ATTENDANCE_RECORDED','attendance',6,'{\"staff\": \"(M)vijaya_mam\", \"date\": \"2026-10-13\", \"shift\": \"Evening\", \"after\": {\"status\": \"PRESENT\", \"reason\": null}}','2026-10-13 10:36:42'),(52,1,'ATTENDANCE_RECORDED','attendance',7,'{\"staff\": \"abhi\", \"date\": \"2026-10-13\", \"shift\": \"Evening\", \"after\": {\"status\": \"LEAVE\", \"reason\": null}}','2026-10-13 10:36:46'),(53,1,'ATTENDANCE_RECORDED','attendance',8,'{\"staff\": \"chetan_bhai\", \"date\": \"2026-10-13\", \"shift\": \"Evening\", \"after\": {\"status\": \"ABSENT\", \"reason\": null}}','2026-10-13 10:36:50'),(54,1,'ATTENDANCE_RECORDED','attendance',9,'{\"staff\": \"vinit\", \"date\": \"2026-10-13\", \"shift\": \"Evening\", \"after\": {\"status\": \"LEAVE\", \"reason\": null}}','2026-10-13 10:36:54'),(55,1,'ATTENDANCE_CORRECTED','attendance',5,'{\"staff\": \"yash\", \"date\": \"2026-10-13\", \"shift\": \"Morning\", \"before\": {\"status\": \"LEAVE\", \"reason\": null}, \"after\": {\"status\": \"ABSENT\", \"reason\": null}}','2026-10-13 10:37:17'),(56,1,'USER_CREATED','user',13,'Created employee account','2026-10-13 10:39:00'),(57,1,'ATTENDANCE_RECORDED','attendance',10,'{\"staff\": \"manasi\", \"date\": \"2026-10-13\", \"shift\": \"Morning\", \"after\": {\"status\": \"LEAVE\", \"reason\": null}}','2026-10-13 10:39:21'),(58,1,'USER_UPDATED','user',13,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"manasi\", \"full_name\": \"manasi\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"manasi\", \"full_name\": \"manasi\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": false, \"default_shift\": \"Morning\"}}','2026-10-13 10:40:30'),(59,1,'USER_UPDATED','user',11,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"fychetan\", \"full_name\": \"chetanFY\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 0, \"default_shift\": null}, \"after\": {\"username\": \"fychetan\", \"full_name\": \"Chetan Shersat_FY\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": false, \"default_shift\": null}}','2026-10-13 10:41:02'),(60,1,'USER_UPDATED','user',5,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"chetan\", \"full_name\": \"chetan_bhai\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": \"Evening\"}, \"after\": {\"username\": \"chetan\", \"full_name\": \"Chetan_bhai\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-13 10:41:13'),(61,1,'USER_UPDATED','user',12,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"vijaya_mam\", \"full_name\": \"(M)vijaya_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": 1, \"default_shift\": \"Evening\"}, \"after\": {\"username\": \"vijaya_mam\", \"full_name\": \"(M)Vijaya_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-13 10:41:24'),(62,1,'USER_UPDATED','user',3,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"abhi\", \"full_name\": \"abhi\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": \"Evening\"}, \"after\": {\"username\": \"abhi\", \"full_name\": \"Abhi\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-13 10:41:33'),(63,1,'USER_UPDATED','user',9,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"jayram\", \"full_name\": \"jayram\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 0, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"jayram\", \"full_name\": \"Jayram\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": false, \"default_shift\": \"Morning\"}}','2026-10-13 10:41:46'),(64,1,'USER_UPDATED','user',13,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"manasi\", \"full_name\": \"manasi\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 0, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"manasi\", \"full_name\": \"Manasi\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": false, \"default_shift\": \"Morning\"}}','2026-10-13 10:41:59'),(65,1,'USER_UPDATED','user',6,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"manohar\", \"full_name\": \"manohar\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"manohar\", \"full_name\": \"Manohar\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Morning\"}}','2026-10-13 10:42:07'),(66,1,'USER_UPDATED','user',10,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"omkar\", \"full_name\": \"omkar\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"omkar\", \"full_name\": \"Omkar\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Morning\"}}','2026-10-13 10:42:16'),(67,1,'USER_UPDATED','user',8,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"satyam\", \"full_name\": \"satyam\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"satyam\", \"full_name\": \"Satyam\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Morning\"}}','2026-10-13 10:42:27'),(68,1,'USER_UPDATED','user',7,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"vinit\", \"full_name\": \"vinit\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": \"Evening\"}, \"after\": {\"username\": \"vinit\", \"full_name\": \"Vinit\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-13 10:42:35'),(69,1,'USER_UPDATED','user',4,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"yash\", \"full_name\": \"yash\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 1, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"yash\", \"full_name\": \"Yash\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": true, \"default_shift\": \"Morning\"}}','2026-10-13 10:42:43'),(70,1,'USER_CREATED','user',14,'Created manager account','2026-10-13 10:43:38'),(71,1,'USER_UPDATED','user',14,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"namrata_mam\", \"full_name\": \"(M)Namrata_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": 1, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"namrata_mam\", \"full_name\": \"(M)Namrata_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": true, \"default_shift\": \"Morning\"}}','2026-10-13 10:43:56'),(72,1,'USER_UPDATED','user',14,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"namrata_mam\", \"full_name\": \"(M)Namrata_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": 1, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"namrata_mam\", \"full_name\": \"(M)Namrata_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-13 10:44:47'),(73,1,'ATTENDANCE_RECORDED','attendance',11,'{\"staff\": \"(M)Namrata_mam\", \"date\": \"2026-10-13\", \"shift\": \"Evening\", \"after\": {\"status\": \"PRESENT\", \"reason\": null}}','2026-10-13 10:44:56'),(74,1,'AUTH_LOGIN','user',1,NULL,'2026-10-13 13:25:06'),(75,1,'DISPENSER_CREATED','dispenser',1,'East 1','2026-10-13 14:10:20'),(76,1,'FUEL_DELETED','fuel',4,'{\"deleted\": {\"id\": 4, \"name\": \"string\", \"price\": \"0.00\", \"stock_litres\": \"0.00\"}}','2026-10-13 14:18:58'),(77,1,'FUEL_DELETED','fuel',1,'{\"deleted\": {\"id\": 1, \"name\": \"Petrol\", \"price\": \"103.50\", \"stock_litres\": \"0.00\"}}','2026-10-13 14:19:16'),(78,1,'FUEL_DELETED','fuel',5,'{\"deleted\": {\"id\": 5, \"name\": \"Diesel\", \"price\": \"454.00\", \"stock_litres\": \"4555.00\"}}','2026-10-13 14:19:36'),(79,1,'FUEL_DELETED','fuel',3,'{\"deleted\": {\"id\": 3, \"name\": \"Diesel\", \"price\": \"77.50\", \"stock_litres\": \"0.00\"}}','2026-10-13 14:19:41'),(80,1,'FUEL_DELETED','fuel',7,'{\"deleted\": {\"id\": 7, \"name\": \"Petrol\", \"price\": \"44.00\", \"stock_litres\": \"4.00\"}}','2026-10-13 14:19:51'),(81,1,'STATION_SETTINGS_UPDATED','station_settings',1,'{\"before\": {\"station_name\": \"Sharda&Alianka Petroleum\", \"city\": \"Mumbai\", \"city_petrol_rate\": null, \"city_diesel_rate\": null}, \"after\": {\"station_name\": \"My Petrol Pump\", \"city\": \"Mumbai\", \"city_petrol_rate\": \"112.52\", \"city_diesel_rate\": \"98.15\"}}','2026-10-13 14:46:13'),(82,1,'STATION_SETTINGS_UPDATED','station_settings',1,'{\"before\": {\"station_name\": \"My Petrol Pump\", \"city\": \"Mumbai\", \"city_petrol_rate\": \"112.52\", \"city_diesel_rate\": \"98.15\"}, \"after\": {\"station_name\": \"My Petrol Pump\", \"city\": \"Pune\", \"city_petrol_rate\": \"112.52\", \"city_diesel_rate\": \"98.15\"}}','2026-10-13 14:50:32'),(83,1,'AUTH_LOGOUT','user',1,NULL,'2026-10-13 14:54:39'),(84,2,'AUTH_LOGIN','user',2,NULL,'2026-10-13 14:54:48'),(85,2,'AUTH_LOGOUT','user',2,NULL,'2026-10-13 14:57:12'),(86,5,'AUTH_LOGIN','user',5,NULL,'2026-10-13 14:57:25'),(87,1,'AUTH_LOGIN','user',1,NULL,'2026-10-19 19:17:38'),(88,1,'USER_UPDATED','user',14,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"namrata_mam\", \"full_name\": \"(M)Namrata_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": 1, \"default_shift\": \"Evening\"}, \"after\": {\"username\": \"namrata_mam\", \"full_name\": \"(M)Namrata_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": false, \"default_shift\": \"Evening\"}}','2026-10-19 19:19:10'),(89,1,'USER_UPDATED','user',14,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"namrata_mam\", \"full_name\": \"(M)Namrata_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": 0, \"default_shift\": \"Evening\"}, \"after\": {\"username\": \"namrata_mam\", \"full_name\": \"(M)Namrata_mam\", \"email\": null, \"role\": \"MANAGER\", \"is_active\": true, \"default_shift\": \"Evening\"}}','2026-10-19 19:19:17'),(90,1,'STATION_NAME_UPDATED','station_settings',1,'{\"before\": \"My Petrol Pump\", \"after\": \"Sharda Petroleum\"}','2026-10-19 19:19:52'),(91,1,'AUTH_LOGIN','user',1,NULL,'2026-10-19 19:23:10'),(92,1,'AUTH_LOGIN','user',1,NULL,'2026-10-25 13:41:06'),(93,1,'FUEL_DELETED','fuel',2,'{\"deleted\": {\"id\": 2, \"name\": \"Petrol\", \"price\": \"103.50\", \"stock_litres\": \"0.00\"}}','2026-10-25 14:02:21'),(94,1,'FUEL_DELETED','fuel',6,'{\"deleted\": {\"id\": 6, \"name\": \"Petrol\", \"price\": \"5.00\", \"stock_litres\": \"5.00\"}}','2026-10-25 14:02:25'),(95,1,'USER_UPDATED','user',13,'{\"changed\": [\"username\", \"full_name\", \"email\", \"role\", \"is_active\", \"default_shift\"], \"before\": {\"username\": \"manasi\", \"full_name\": \"Manasi\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": 0, \"default_shift\": \"Morning\"}, \"after\": {\"username\": \"shingade\", \"full_name\": \"shinagde\", \"email\": null, \"role\": \"EMPLOYEE\", \"is_active\": false, \"default_shift\": \"Morning\"}}','2026-10-25 14:06:00'),(96,1,'USER_CREATED','user',15,'Created manager account','2026-10-25 14:07:06'),(97,1,'AUTH_LOGOUT','user',1,NULL,'2026-10-25 14:07:31'),(98,15,'AUTH_LOGIN','user',15,NULL,'2026-10-25 14:07:38'),(99,15,'AUTH_LOGOUT','user',15,NULL,'2026-10-25 14:08:06'),(100,15,'AUTH_LOGIN','user',15,NULL,'2026-10-25 14:08:45'),(101,15,'AUTH_LOGOUT','user',15,NULL,'2026-10-25 14:09:05'),(102,1,'AUTH_LOGIN','user',1,NULL,'2026-10-25 14:09:08');
/*!40000 ALTER TABLE `audit_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `discrepancy_notes`
--

DROP TABLE IF EXISTS `discrepancy_notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `discrepancy_notes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `reconciliation_id` bigint NOT NULL,
  `employee_user_id` int NOT NULL,
  `explanation` text NOT NULL,
  `manager_response` text,
  `review_status` enum('OPEN','ACKNOWLEDGED') NOT NULL DEFAULT 'OPEN',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `responded_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_note_reconciliation` (`reconciliation_id`),
  KEY `fk_note_employee` (`employee_user_id`),
  CONSTRAINT `fk_note_employee` FOREIGN KEY (`employee_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_note_reconciliation` FOREIGN KEY (`reconciliation_id`) REFERENCES `reconciliations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `discrepancy_notes`
--

LOCK TABLES `discrepancy_notes` WRITE;
/*!40000 ALTER TABLE `discrepancy_notes` DISABLE KEYS */;
/*!40000 ALTER TABLE `discrepancy_notes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dispensers`
--

DROP TABLE IF EXISTS `dispensers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dispensers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `identifier` varchar(40) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dispensers`
--

LOCK TABLES `dispensers` WRITE;
/*!40000 ALTER TABLE `dispensers` DISABLE KEYS */;
INSERT INTO `dispensers` VALUES (1,'East 1',1);
/*!40000 ALTER TABLE `dispensers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `employee_profiles`
--

DROP TABLE IF EXISTS `employee_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_profiles` (
  `user_id` int NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `joining_date` date DEFAULT NULL,
  `default_shift` varchar(30) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_employee_profile_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `employee_profiles`
--

LOCK TABLES `employee_profiles` WRITE;
/*!40000 ALTER TABLE `employee_profiles` DISABLE KEYS */;
INSERT INTO `employee_profiles` VALUES (2,NULL,NULL,'Morning','2026-10-13 10:31:23'),(3,NULL,NULL,'Evening','2026-10-13 10:31:40'),(4,NULL,NULL,'Morning','2026-10-13 10:33:06'),(5,NULL,NULL,'Evening','2026-10-13 10:31:52'),(6,NULL,NULL,'Morning','2026-10-13 10:32:17'),(7,NULL,NULL,'Evening','2026-10-13 10:32:56'),(8,NULL,NULL,'Morning','2026-10-13 10:32:47'),(9,NULL,NULL,'Morning','2026-10-13 10:32:06'),(10,NULL,NULL,'Morning','2026-10-13 10:32:28'),(11,NULL,NULL,NULL,'2026-10-13 10:41:02'),(12,NULL,NULL,'Evening','2026-10-13 10:35:07'),(13,NULL,NULL,'Morning','2026-10-13 10:39:00'),(14,NULL,NULL,'Evening','2026-10-13 10:44:47'),(15,NULL,NULL,'Morning','2026-10-25 14:07:06');
/*!40000 ALTER TABLE `employee_profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fuels`
--

DROP TABLE IF EXISTS `fuels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fuels` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `stock_litres` decimal(10,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fuels`
--

LOCK TABLES `fuels` WRITE;
/*!40000 ALTER TABLE `fuels` DISABLE KEYS */;
INSERT INTO `fuels` VALUES (8,'Petrol Demo',104.50,12000.00),(9,'Diesel Demo',94.50,15000.00);
/*!40000 ALTER TABLE `fuels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_transactions`
--

DROP TABLE IF EXISTS `inventory_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_transactions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tank_id` int DEFAULT NULL,
  `fuel_id` int NOT NULL,
  `transaction_type` enum('DELIVERY','ADJUSTMENT','SALE','VOID') NOT NULL,
  `quantity_litres` decimal(12,2) NOT NULL,
  `reference_type` varchar(50) DEFAULT NULL,
  `reference_id` bigint DEFAULT NULL,
  `reason` varchar(500) DEFAULT NULL,
  `created_by` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_inventory_fuel_date` (`fuel_id`,`created_at`),
  KEY `fk_inventory_tank` (`tank_id`),
  KEY `fk_inventory_user` (`created_by`),
  CONSTRAINT `fk_inventory_fuel` FOREIGN KEY (`fuel_id`) REFERENCES `fuels` (`id`),
  CONSTRAINT `fk_inventory_tank` FOREIGN KEY (`tank_id`) REFERENCES `tanks` (`id`),
  CONSTRAINT `fk_inventory_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_transactions`
--

LOCK TABLES `inventory_transactions` WRITE;
/*!40000 ALTER TABLE `inventory_transactions` DISABLE KEYS */;
INSERT INTO `inventory_transactions` VALUES (1,NULL,8,'DELIVERY',12000.00,'TANKER_DELIVERY',1,'Demo data for 13-10-2026',1,'2026-10-13 08:55:15'),(2,NULL,9,'DELIVERY',15000.00,'TANKER_DELIVERY',2,'Demo data for 13-10-2026',1,'2026-10-13 08:55:15');
/*!40000 ALTER TABLE `inventory_transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nozzle_readings`
--

DROP TABLE IF EXISTS `nozzle_readings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nozzle_readings` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `shift_id` bigint NOT NULL,
  `nozzle_id` int NOT NULL,
  `employee_user_id` int DEFAULT NULL,
  `opening_totalizer` decimal(14,3) NOT NULL,
  `closing_totalizer` decimal(14,3) DEFAULT NULL,
  `rate_per_litre` decimal(10,2) NOT NULL,
  `litres_sold` decimal(14,3) DEFAULT NULL,
  `expected_sales` decimal(14,2) DEFAULT NULL,
  `status` enum('OPEN','CLOSED','FLAGGED','VOID') NOT NULL DEFAULT 'OPEN',
  `recorded_by` int NOT NULL,
  `correction_reason` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_nozzle_shift` (`shift_id`,`nozzle_id`),
  KEY `fk_nozzle_reading_nozzle` (`nozzle_id`),
  KEY `fk_nozzle_reading_employee` (`employee_user_id`),
  KEY `fk_nozzle_reading_user` (`recorded_by`),
  CONSTRAINT `fk_nozzle_reading_employee` FOREIGN KEY (`employee_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_nozzle_reading_nozzle` FOREIGN KEY (`nozzle_id`) REFERENCES `nozzles` (`id`),
  CONSTRAINT `fk_nozzle_reading_shift` FOREIGN KEY (`shift_id`) REFERENCES `shifts` (`id`),
  CONSTRAINT `fk_nozzle_reading_user` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nozzle_readings`
--

LOCK TABLES `nozzle_readings` WRITE;
/*!40000 ALTER TABLE `nozzle_readings` DISABLE KEYS */;
/*!40000 ALTER TABLE `nozzle_readings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nozzles`
--

DROP TABLE IF EXISTS `nozzles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nozzles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `identifier` varchar(40) NOT NULL,
  `dispenser_id` int NOT NULL,
  `fuel_id` int NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`),
  KEY `fk_nozzle_dispenser` (`dispenser_id`),
  KEY `fk_nozzle_fuel` (`fuel_id`),
  CONSTRAINT `fk_nozzle_dispenser` FOREIGN KEY (`dispenser_id`) REFERENCES `dispensers` (`id`),
  CONSTRAINT `fk_nozzle_fuel` FOREIGN KEY (`fuel_id`) REFERENCES `fuels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nozzles`
--

LOCK TABLES `nozzles` WRITE;
/*!40000 ALTER TABLE `nozzles` DISABLE KEYS */;
/*!40000 ALTER TABLE `nozzles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reconciliations`
--

DROP TABLE IF EXISTS `reconciliations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reconciliations` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `shift_id` bigint NOT NULL,
  `expected_cash` decimal(14,2) NOT NULL DEFAULT '0.00',
  `expected_upi` decimal(14,2) NOT NULL DEFAULT '0.00',
  `expected_card` decimal(14,2) NOT NULL DEFAULT '0.00',
  `actual_cash` decimal(14,2) NOT NULL DEFAULT '0.00',
  `actual_upi` decimal(14,2) NOT NULL DEFAULT '0.00',
  `actual_card` decimal(14,2) NOT NULL DEFAULT '0.00',
  `status` enum('DRAFT','SUBMITTED','REVIEWED') NOT NULL DEFAULT 'DRAFT',
  `notes` varchar(1000) DEFAULT NULL,
  `recorded_by` int NOT NULL,
  `reviewed_by` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `shift_id` (`shift_id`),
  KEY `fk_reconciliation_recorder` (`recorded_by`),
  KEY `fk_reconciliation_reviewer` (`reviewed_by`),
  CONSTRAINT `fk_reconciliation_recorder` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_reconciliation_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_reconciliation_shift` FOREIGN KEY (`shift_id`) REFERENCES `shifts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reconciliations`
--

LOCK TABLES `reconciliations` WRITE;
/*!40000 ALTER TABLE `reconciliations` DISABLE KEYS */;
/*!40000 ALTER TABLE `reconciliations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `revoked_tokens`
--

DROP TABLE IF EXISTS `revoked_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revoked_tokens` (
  `token_id` char(36) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`token_id`),
  KEY `idx_revoked_tokens_expiry` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `revoked_tokens`
--

LOCK TABLES `revoked_tokens` WRITE;
/*!40000 ALTER TABLE `revoked_tokens` DISABLE KEYS */;
INSERT INTO `revoked_tokens` VALUES ('1720a8eb-18d3-480b-94da-eb98a0d00ca7','2026-10-13 16:50:42','2026-10-13 09:29:13'),('3d82227b-4a20-41dc-b6a8-2ce1dd41da60','2026-10-25 22:08:45','2026-10-25 14:09:05'),('6380cd4f-97f8-4518-b485-f5aec9c9c63e','2026-10-13 21:25:06','2026-10-13 14:54:39'),('66a5ae87-6db6-46b9-8a89-4c4987134e92','2026-10-13 15:55:15','2026-10-13 07:55:58'),('8a9e6222-1902-4ea4-bb6d-6432386d0375','2026-10-25 22:07:38','2026-10-25 14:08:06'),('8b895e9e-b3d0-45ad-a962-e7ed573fbd51','2026-10-25 21:41:06','2026-10-25 14:07:31'),('9697fed4-b4e6-4de9-abf2-8d176dfe488a','2026-10-13 17:29:34','2026-10-13 10:30:25'),('add4210f-0f47-4dc7-bf52-7d0b37f41e28','2026-10-13 22:54:48','2026-10-13 14:57:12'),('b45fb49c-6984-41be-b212-ee377e83f8c0','2026-10-13 15:56:08','2026-10-13 07:56:59');
/*!40000 ALTER TABLE `revoked_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shift_assignments`
--

DROP TABLE IF EXISTS `shift_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shift_assignments` (
  `shift_id` bigint NOT NULL,
  `user_id` int NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`shift_id`,`user_id`),
  KEY `fk_assignment_user` (`user_id`),
  CONSTRAINT `fk_assignment_shift` FOREIGN KEY (`shift_id`) REFERENCES `shifts` (`id`),
  CONSTRAINT `fk_assignment_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shift_assignments`
--

LOCK TABLES `shift_assignments` WRITE;
/*!40000 ALTER TABLE `shift_assignments` DISABLE KEYS */;
/*!40000 ALTER TABLE `shift_assignments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shift_templates`
--

DROP TABLE IF EXISTS `shift_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shift_templates` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `starts_at` time NOT NULL,
  `ends_at` time NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shift_templates`
--

LOCK TABLES `shift_templates` WRITE;
/*!40000 ALTER TABLE `shift_templates` DISABLE KEYS */;
INSERT INTO `shift_templates` VALUES (1,'Morning','06:00:00','14:00:00',1),(2,'Evening','14:00:00','22:00:00',1);
/*!40000 ALTER TABLE `shift_templates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shifts`
--

DROP TABLE IF EXISTS `shifts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shifts` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `shift_date` date NOT NULL,
  `template_id` int NOT NULL,
  `manager_user_id` int DEFAULT NULL,
  `status` enum('SCHEDULED','OPEN','AWAITING_RECONCILIATION','RECONCILED','CLOSED','VOID') NOT NULL DEFAULT 'SCHEDULED',
  `notes` varchar(1000) DEFAULT NULL,
  `opened_at` datetime DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `created_by` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_shift_date_template` (`shift_date`,`template_id`),
  KEY `idx_shifts_date_status` (`shift_date`,`status`),
  KEY `fk_shift_template` (`template_id`),
  KEY `fk_shift_manager` (`manager_user_id`),
  KEY `fk_shift_creator` (`created_by`),
  CONSTRAINT `fk_shift_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_shift_manager` FOREIGN KEY (`manager_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_shift_template` FOREIGN KEY (`template_id`) REFERENCES `shift_templates` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shifts`
--

LOCK TABLES `shifts` WRITE;
/*!40000 ALTER TABLE `shifts` DISABLE KEYS */;
/*!40000 ALTER TABLE `shifts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `station_settings`
--

DROP TABLE IF EXISTS `station_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `station_settings` (
  `id` tinyint NOT NULL,
  `station_name` varchar(120) NOT NULL DEFAULT 'My Petrol Pump',
  `city` varchar(100) NOT NULL DEFAULT 'Mumbai',
  `city_petrol_rate` decimal(10,2) DEFAULT NULL,
  `city_diesel_rate` decimal(10,2) DEFAULT NULL,
  `city_rate_updated_at` datetime DEFAULT NULL,
  `updated_by` int DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_station_settings_user` (`updated_by`),
  CONSTRAINT `fk_station_settings_user` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `station_settings`
--

LOCK TABLES `station_settings` WRITE;
/*!40000 ALTER TABLE `station_settings` DISABLE KEYS */;
INSERT INTO `station_settings` VALUES (1,'Sharda Petroleum','Pune',112.52,98.15,'2026-10-13 20:20:33',1,'2026-10-19 19:19:52');
/*!40000 ALTER TABLE `station_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tank_calibration_points`
--

DROP TABLE IF EXISTS `tank_calibration_points`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tank_calibration_points` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tank_id` int NOT NULL,
  `height_mm` decimal(10,2) NOT NULL,
  `volume_litres` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_calibration_point` (`tank_id`,`height_mm`),
  CONSTRAINT `fk_calibration_tank` FOREIGN KEY (`tank_id`) REFERENCES `tanks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tank_calibration_points`
--

LOCK TABLES `tank_calibration_points` WRITE;
/*!40000 ALTER TABLE `tank_calibration_points` DISABLE KEYS */;
/*!40000 ALTER TABLE `tank_calibration_points` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tank_readings`
--

DROP TABLE IF EXISTS `tank_readings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tank_readings` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tank_id` int NOT NULL,
  `measured_at` datetime NOT NULL,
  `dip_mm` decimal(10,2) NOT NULL,
  `volume_litres` decimal(12,2) NOT NULL,
  `recorded_by` int NOT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `is_void` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_tank_readings_tank_date` (`tank_id`,`measured_at`),
  KEY `fk_reading_user` (`recorded_by`),
  CONSTRAINT `fk_reading_tank` FOREIGN KEY (`tank_id`) REFERENCES `tanks` (`id`),
  CONSTRAINT `fk_reading_user` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tank_readings`
--

LOCK TABLES `tank_readings` WRITE;
/*!40000 ALTER TABLE `tank_readings` DISABLE KEYS */;
/*!40000 ALTER TABLE `tank_readings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tanker_deliveries`
--

DROP TABLE IF EXISTS `tanker_deliveries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tanker_deliveries` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `fuel_id` int NOT NULL,
  `tank_id` int DEFAULT NULL,
  `quantity_litres` decimal(12,2) NOT NULL,
  `stock_before_litres` decimal(12,2) NOT NULL,
  `stock_after_litres` decimal(12,2) NOT NULL,
  `received_at` datetime NOT NULL,
  `supplier_name` varchar(120) DEFAULT NULL,
  `challan_number` varchar(80) DEFAULT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `created_by` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_delivery_fuel_received` (`fuel_id`,`received_at`),
  KEY `idx_delivery_tank_received` (`tank_id`,`received_at`),
  KEY `fk_delivery_user` (`created_by`),
  CONSTRAINT `fk_delivery_fuel` FOREIGN KEY (`fuel_id`) REFERENCES `fuels` (`id`),
  CONSTRAINT `fk_delivery_tank` FOREIGN KEY (`tank_id`) REFERENCES `tanks` (`id`),
  CONSTRAINT `fk_delivery_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tanker_deliveries`
--

LOCK TABLES `tanker_deliveries` WRITE;
/*!40000 ALTER TABLE `tanker_deliveries` DISABLE KEYS */;
INSERT INTO `tanker_deliveries` VALUES (1,8,NULL,12000.00,0.00,12000.00,'2026-10-13 09:00:00','Tech-E20 Demo Supplier','DEMO-PT-20261013','Clearly labelled demonstration record',1,'2026-10-13 08:55:15'),(2,9,NULL,15000.00,0.00,15000.00,'2026-10-13 09:00:00','Tech-E20 Demo Supplier','DEMO-DI-20261013','Clearly labelled demonstration record',1,'2026-10-13 08:55:15');
/*!40000 ALTER TABLE `tanker_deliveries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tanks`
--

DROP TABLE IF EXISTS `tanks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tanks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `identifier` varchar(40) NOT NULL,
  `fuel_id` int NOT NULL,
  `capacity_litres` decimal(12,2) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`),
  KEY `fk_tank_fuel` (`fuel_id`),
  CONSTRAINT `fk_tank_fuel` FOREIGN KEY (`fuel_id`) REFERENCES `fuels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tanks`
--

LOCK TABLES `tanks` WRITE;
/*!40000 ALTER TABLE `tanks` DISABLE KEYS */;
/*!40000 ALTER TABLE `tanks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `full_name` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('OWNER','MANAGER','EMPLOYEE') NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_username` (`username`),
  UNIQUE KEY `uq_users_email` (`email`),
  KEY `idx_users_role_active` (`role`,`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'suresh11','sureshshingade38700@gmail.com','SURESH BAJRANG SHINGADE','$argon2id$v=19$m=65536,t=3,p=4$sy9Fvc2Ouqp5mAjAg3tMzw$3AcylRLWYl9EfLb8rVONrok40v3BwM1zTvN2NZMS8VQ','OWNER',1,'2026-10-12 17:45:14','2026-10-13 09:28:52'),(2,'nikhil',NULL,'(M)Nikhil_Sir','$argon2id$v=19$m=65536,t=3,p=4$gU72TVYxaffJDlNMR6OHvQ$tY6Au4mrDL/eUsRivsm2Z7DXW/vTqrzFpkmvbzTVv+k','MANAGER',1,'2026-10-12 17:54:28','2026-10-13 09:54:45'),(3,'abhi',NULL,'Abhi','$argon2id$v=19$m=65536,t=3,p=4$OVlad4OjtdD3S3o7siA6Og$67K9uyrhNXYswQTQTA4Vfduo+/Rkt8VN9ShcfvGhbRk','EMPLOYEE',1,'2026-10-12 17:57:00','2026-10-13 10:41:33'),(4,'yash',NULL,'Yash','$argon2id$v=19$m=65536,t=3,p=4$fL04nHGHVRrn2OAMzfi/0Q$dmx0TLk2E7zIQ9jZstF3GNcc7yBRufk4Zc/MdOynJyo','EMPLOYEE',1,'2026-10-13 09:52:15','2026-10-13 10:42:43'),(5,'chetan',NULL,'Chetan_bhai','$argon2id$v=19$m=65536,t=3,p=4$RyC5S4LsjG0gxWwb6V3XtA$Nadn0/KFPEnUpLbKiuGF1iIrWBT75ZDWf8Jsf2/YUFs','EMPLOYEE',1,'2026-10-13 09:52:42','2026-10-13 10:41:13'),(6,'manohar',NULL,'Manohar','$argon2id$v=19$m=65536,t=3,p=4$iz3kp9r4dN5aJdWzTJ/tcA$1J839ouZVYtTxxQMqYBTCNmIJRj/O/8lfEQ/lzZlKRE','EMPLOYEE',1,'2026-10-13 09:53:03','2026-10-13 10:42:07'),(7,'vinit',NULL,'Vinit','$argon2id$v=19$m=65536,t=3,p=4$mS7XTryLjyvXUbOyrILFGQ$ViweFuG7cd0vdTVGOyPorOAxDOKUTJofSvq7yBy57fk','EMPLOYEE',1,'2026-10-13 09:53:37','2026-10-13 10:42:35'),(8,'satyam',NULL,'Satyam','$argon2id$v=19$m=65536,t=3,p=4$3J0L3kI8xZSUuXrBX/LXEg$LhF2VdhP5L7Wq58itUj8Zf0Rr/tfiT53yAkCtEllSIA','EMPLOYEE',1,'2026-10-13 09:55:18','2026-10-13 10:42:27'),(9,'jayram',NULL,'Jayram','$argon2id$v=19$m=65536,t=3,p=4$POYPf2R8AZJViMhZjO7GYw$cTU3qIfJPx7E5OHcKlttk2IPdiHVVrbyIelxJECcMtc','EMPLOYEE',0,'2026-10-13 09:56:13','2026-10-13 10:41:46'),(10,'omkar',NULL,'Omkar','$argon2id$v=19$m=65536,t=3,p=4$M8Bq92dh/7HIYWNra9TFlw$sCAWBONccTJfahS0jBiy+juRYGcSzwJtrPL91QbpLjg','EMPLOYEE',1,'2026-10-13 09:57:44','2026-10-13 10:42:16'),(11,'fychetan',NULL,'Chetan Shersat_FY','$argon2id$v=19$m=65536,t=3,p=4$vi/gSoD83aFD9oLgFE+27g$x62XL5d3KPg5+z+l7sKxY5+t0alr84ODY8kbI+4SoJs','EMPLOYEE',0,'2026-10-13 09:58:44','2026-10-13 10:41:02'),(12,'vijaya_mam',NULL,'(M)Vijaya_mam','$argon2id$v=19$m=65536,t=3,p=4$/7gxYd6aLTR/4GgOFMjo6g$oGaSZRanqgQj8IcJjfv5IeK7D1MKTHReHKsEtc1tXwc','MANAGER',1,'2026-10-13 10:34:43','2026-10-13 10:41:24'),(13,'shingade',NULL,'shinagde','$argon2id$v=19$m=65536,t=3,p=4$yAA3B8G9MlgPEtfuHYEjpQ$ASRaAcNktUf7YDylHNkom9vu4Rb24YGADMs7F/8GMg4','EMPLOYEE',0,'2026-10-13 10:39:00','2026-10-25 14:06:00'),(14,'namrata_mam',NULL,'(M)Namrata_mam','$argon2id$v=19$m=65536,t=3,p=4$BJGhuf4bN9sVocakoUFjCg$VKcWfCaWkWuyD4oDPVxVX6y15nht4uPZgfDlhUWZdj8','MANAGER',1,'2026-10-13 10:43:38','2026-10-19 19:19:17'),(15,'demo',NULL,'demo','$argon2id$v=19$m=65536,t=3,p=4$AHCQPV2ID3NfotoJiLPwAA$AYI00hUfmX0VxJPzfLEl6MP8SQ4Qa2vLOTv8+3cqSpY','MANAGER',1,'2026-10-25 14:07:06','2026-10-25 14:07:06');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-25 20:36:59
