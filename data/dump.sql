-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: drl_train
-- ------------------------------------------------------
-- Server version	8.0.46-0ubuntu0.22.04.3

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
-- Dumping data for table `robots`
--

LOCK TABLES `robots` WRITE;
/*!40000 ALTER TABLE `robots` DISABLE KEYS */;
INSERT INTO `robots` (`robot_id`, `display_name`, `dof_count`, `mass_kg`, `urdf_sha256`, `urdf_path`, `notes`, `created_at`) VALUES ('d1_edu_12dof','智元 D1 edu',12,15.1860,'c7d5ad671cda322bcb5c949ae6c11acbb937eb2113a5feaa62b025c1e383e2c4','~/self-AGI/urdf/edu_description/urdf/edu.urdf','训狗 D1 项目主力。总质量与 robot_lab 官方 D1 配置一致（15.186 kg）。','2026-09-01 00:18:09');
/*!40000 ALTER TABLE `robots` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `runs`
--

LOCK TABLES `runs` WRITE;
/*!40000 ALTER TABLE `runs` DISABLE KEYS */;
INSERT INTO `runs` (`run_id`, `robot_id`, `label`, `run_dir`, `started_at`, `git_commit`, `kp`, `kd`, `default_abad`, `default_hip_front`, `default_hip_rear`, `default_knee`, `action_scale`, `num_envs`, `max_iterations`, `completed`, `iterations_done`, `mean_reward`, `episode_length`, `mean_action_std`, `error_vel_xy`, `error_vel_yaw`, `base_contact`, `gait_consistency`, `change_summary`, `verdict`, `notes`, `created_at`) VALUES (1,'d1_edu_12dof','R16','2026-08-30_20-53-42','2026-08-30 20:53:42',NULL,20.0000,0.5000,0.0000,0.8000,0.8000,NULL,0.2500,4096,1000,1,1000,36.670086,997.585,0.380983,0.220907,0.253567,0.004762,1.152000,'feet_slide 权重从 0 改回 -0.25（R15 唯一改动的回撤）','达标',NULL,'2026-09-01 00:19:03');
/*!40000 ALTER TABLE `runs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `reward_terms`
--

LOCK TABLES `reward_terms` WRITE;
/*!40000 ALTER TABLE `reward_terms` DISABLE KEYS */;
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'action_rate_l2',-0.010000000000,NULL,-0.054013825208);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'air_time_excess',0.000000000000,'{\"cap\": 0.5, \"max_air_time\": 0.25}',0.000000000000);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'ang_vel_xy_l2',-0.050000000000,NULL,-0.037698652409);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'contact_time_deficit',0.000000000000,'{\"min_contact_time\": 0.1}',0.000000000000);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'dof_acc_l2',-0.000000250000,NULL,-0.033239900507);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'dof_pos_limits',-1.000000000000,NULL,-0.000799962325);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'dof_torques_l2',-0.000050000000,NULL,-0.018499773927);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'feet_air_time',0.000000000000,'{\"threshold\": 0.1, \"command_name\": \"base_velocity\"}',0.000000000000);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'feet_slide',-0.250000000000,NULL,-0.071761673689);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'flat_orientation_l2',-2.500000000000,NULL,-0.008763444843);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'lin_vel_z_l2',-2.000000000000,NULL,-0.016847920790);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'track_ang_vel_z_exp',0.750000000000,'{\"std\": 0.5, \"command_name\": \"base_velocity\"}',0.681743621826);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'track_lin_vel_xy_exp',1.500000000000,'{\"std\": 0.5, \"command_name\": \"base_velocity\"}',1.391660505533);
INSERT INTO `reward_terms` (`run_id`, `term_name`, `weight`, `params`, `measured`) VALUES (1,'undesired_contacts',-1.000000000000,'{\"threshold\": 1.0}',-0.000327334621);
/*!40000 ALTER TABLE `reward_terms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `gait_probe`
--

LOCK TABLES `gait_probe` WRITE;
/*!40000 ALTER TABLE `gait_probe` DISABLE KEYS */;
INSERT INTO `gait_probe` (`run_id`, `leg`, `duty`, `air_s`, `contact_s`, `clearance_avg`, `slide`, `period_s`) VALUES (1,'FL',0.612600,NULL,NULL,NULL,NULL,NULL);
INSERT INTO `gait_probe` (`run_id`, `leg`, `duty`, `air_s`, `contact_s`, `clearance_avg`, `slide`, `period_s`) VALUES (1,'FR',0.736000,NULL,NULL,NULL,NULL,NULL);
INSERT INTO `gait_probe` (`run_id`, `leg`, `duty`, `air_s`, `contact_s`, `clearance_avg`, `slide`, `period_s`) VALUES (1,'RL',0.627000,NULL,NULL,NULL,NULL,NULL);
INSERT INTO `gait_probe` (`run_id`, `leg`, `duty`, `air_s`, `contact_s`, `clearance_avg`, `slide`, `period_s`) VALUES (1,'RR',0.555200,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `gait_probe` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed
