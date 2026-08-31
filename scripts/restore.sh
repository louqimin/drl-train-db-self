#!/usr/bin/env bash
# 用 data/dump.sql 覆盖本机数据。⚠ 先清空四张表，是完整替换不是合并。
set -eu

cd "$(dirname "$0")/.."

if [ "$(uname)" = "Darwin" ]; then
  MYSQL=(mysql -u root)
else
  MYSQL=(sudo mysql)
fi

"${MYSQL[@]}" drl_train <<'SQL'
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE gait_probe;
TRUNCATE TABLE reward_terms;
TRUNCATE TABLE runs;
TRUNCATE TABLE robots;
SET FOREIGN_KEY_CHECKS = 1;
SQL

"${MYSQL[@]}" drl_train < data/dump.sql
echo "已用 data/dump.sql 覆盖本机数据"
