  -- 005: 步态探针。一轮四行，每腿一行。
  USE drl_train;

  CREATE TABLE IF NOT EXISTS gait_probe (
    run_id        INT           NOT NULL,
    leg           VARCHAR(8)    NOT NULL,
    duty          DECIMAL(8,6)      NULL,
    air_s         DECIMAL(8,6)      NULL,
    contact_s     DECIMAL(8,6)      NULL,
    clearance_avg DECIMAL(8,6)      NULL,
    slide         DECIMAL(8,6)      NULL,
    period_s      DECIMAL(8,6)      NULL,
    PRIMARY KEY (run_id, leg),
    CONSTRAINT fk_gait_run FOREIGN KEY (run_id)
      REFERENCES runs (run_id)
      ON DELETE CASCADE
      ON UPDATE CASCADE
  ) ENGINE=InnoDB;

