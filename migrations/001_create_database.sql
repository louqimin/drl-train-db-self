-- 001: 建库。字符集与排序规则必须显式指定，不能吃默认值。
CREATE DATABASE IF NOT EXISTS drl_train
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
