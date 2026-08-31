  -- 006: 索引。主键覆盖不到的查询方向在这里补。
  USE drl_train;

  CREATE INDEX idx_runs_robot_time  ON runs (robot_id, started_at);
  CREATE INDEX idx_runs_label       ON runs (label);
  CREATE INDEX idx_reward_term_run  ON reward_terms (term_name, run_id);

