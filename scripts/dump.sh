#!/usr/bin/env bash
# 导出数据（不含表结构）到 data/dump.sql，交给 git 版本化。
set -eu

cd "$(dirname "$0")/.."

if [ "$(uname)" = "Darwin" ]; then
  DUMP=(mysqldump -u root)
else
  DUMP=(sudo mysqldump)
fi

"${DUMP[@]}" \
  --set-gtid-purged=OFF \
  --no-create-info \
  --skip-extended-insert \
  --complete-insert \
  --skip-dump-date \
  --single-transaction \
  drl_train robots runs reward_terms gait_probe \
  > data/dump.sql

echo "data/dump.sql  $(grep -c '' data/dump.sql) 行  $(wc -c < data/dump.sql) 字节"
