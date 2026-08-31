  -- 004: 奖励项。EAV 结构，一轮十几行。项的集合会随轮次增删，故不用宽表。
  USE drl_train;

  CREATE TABLE IF NOT EXISTS reward_terms (
    run_id     INT             NOT NULL,
    term_name  VARCHAR(64)     NOT NULL,
    weight     DECIMAL(16,12)      NULL,
    params     JSON                NULL,
    measured   DECIMAL(16,12)      NULL,
    PRIMARY KEY (run_id, term_name),
    CONSTRAINT fk_reward_run FOREIGN KEY (run_id)
      REFERENCES runs (run_id)
      ON DELETE CASCADE
      ON UPDATE CASCADE
  ) ENGINE=InnoDB;

