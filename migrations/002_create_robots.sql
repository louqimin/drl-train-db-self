-- 002: 机器人型号表。跨项目共享，一台机器一行。
USE drl_train;

CREATE TABLE IF NOT EXISTS robots (
  robot_id      VARCHAR(64)   NOT NULL,
  display_name  VARCHAR(64)   NOT NULL,
  dof_count     SMALLINT      NOT NULL,
  mass_kg       DECIMAL(10,4)     NULL,
  urdf_sha256   CHAR(64)          NULL,
  urdf_path     VARCHAR(255)      NULL,
  notes         TEXT              NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (robot_id)
) ENGINE=InnoDB;
