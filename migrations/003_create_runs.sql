  -- 003: 跑次主表。一轮训练一行。配置段有意反范式化，见 README。
  USE drl_train;

  CREATE TABLE IF NOT EXISTS runs (
    run_id            INT           NOT NULL AUTO_INCREMENT,
    robot_id          VARCHAR(64)   NOT NULL,
    label             VARCHAR(16)       NULL,
    run_dir           VARCHAR(255)  NOT NULL,
    started_at        DATETIME      NOT NULL,
    git_commit        CHAR(40)          NULL,

    kp                DECIMAL(10,4)     NULL,
    kd                DECIMAL(10,4)     NULL,
    default_abad      DECIMAL(8,4)      NULL,
    default_hip_front DECIMAL(8,4)      NULL,
    default_hip_rear  DECIMAL(8,4)      NULL,
    default_knee      DECIMAL(8,4)      NULL,
    action_scale      DECIMAL(8,4)      NULL,
    num_envs          INT               NULL,
    max_iterations    INT               NULL,


    completed         BOOLEAN       NOT NULL DEFAULT FALSE,
    iterations_done   INT               NULL,
    mean_reward       DECIMAL(12,6)     NULL,
    episode_length    DECIMAL(10,3)     NULL,
    mean_action_std   DECIMAL(10,6)     NULL,
    error_vel_xy      DECIMAL(10,6)     NULL,
    error_vel_yaw     DECIMAL(10,6)     NULL,
    base_contact      DECIMAL(10,6)     NULL,
    gait_consistency  DECIMAL(10,6)     NULL,

    change_summary    VARCHAR(255)      NULL,
    verdict           VARCHAR(32)       NULL,
    notes             TEXT              NULL,
    created_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (run_id),
    UNIQUE KEY uq_runs_run_dir (run_dir),
    CONSTRAINT fk_runs_robot FOREIGN KEY (robot_id)
      REFERENCES robots (robot_id)
      ON DELETE RESTRICT
      ON UPDATE CASCADE
  ) ENGINE=InnoDB;
  

