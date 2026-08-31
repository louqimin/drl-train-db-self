#!/usr/bin/env bash
# 按编号顺序跑完 migrations/。幂等，可重复执行。
set -u

cd "$(dirname "$0")/.."

if [ "$(uname)" = "Darwin" ]; then
  MYSQL=(mysql -u root)
else
  MYSQL=(sudo mysql)
fi

echo "使用: ${MYSQL[*]}"
echo

for f in migrations/*.sql; do
  printf '%-36s ' "$f"
  if err=$("${MYSQL[@]}" < "$f" 2>&1); then
    echo "OK"
  else
    echo "跳过/失败 ← ${err}"
  fi
done
