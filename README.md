# drl-train-db-self

DRL 训练跑次数据库。记录每一轮训练的配置、奖励项、步态指标与判读。

## 为什么建库

训了n轮，数据散在 `logs/` 目录、状态档表格和对话记录里，无法交叉查询。
解决策略演变路线的绘制问题。
帮助分析挖掘训练的代际数据的联合价值。

## 备忘：明确Mac和ubuntu双机分工

| | 角色 | 允许做什么 |
|---|---|---|
| **Ubuntu**（训练机） | **权威** | 训练、入库、`dump.sh`、commit、push |
| **Mac** | **只读副本** | `git pull` + `restore.sh`、查询 |

**⚠ Mac 上不要改数据。** `restore.sh` 是清空重灌，本地改动会在下次同步时**无声消失**。
要改判读、补字段，一律在 Ubuntu 改完再同步。

数据流向单向还有一个附带好处：MySQL **8.0.46 → 9.7.1** 是向上导入，安全；反过来有风险。

## 快速上手

```bash
./scripts/setup.sh      # 建库建表。幂等，可重复跑
./scripts/dump.sh       # 导出数据到 data/dump.sql（Ubuntu 侧）
./scripts/restore.sh    # 清空并用 data/dump.sql 覆盖（Mac 侧）

三个脚本都会用 uname 自动判断机器：Mac 用 mysql -u root，Linux 用 sudo mysql。

初次部署：setup.sh → restore.sh。

共有四张表

┌──────────────┬──────────┬────────────────────────────────────┬────────────────────────┐
│      表      │ 一轮几行 │               装什么               │          结构          │
├──────────────┼──────────┼────────────────────────────────────┼────────────────────────┤
│ robots       │ —        │ 机器人型号，跨项目共享             │ 宽表，自然主键         │
├──────────────┼──────────┼────────────────────────────────────┼────────────────────────┤
│ runs         │ 1        │ 跑次标识、硬件配置、训练结果、判读 │ 宽表，代理主键         │
├──────────────┼──────────┼────────────────────────────────────┼────────────────────────┤
│ reward_terms │ 十几     │ 项名、权重、参数、实测值           │ EAV                    │
├──────────────┼──────────┼────────────────────────────────────┼────────────────────────┤
│ gait_probe   │ 4        │ 每腿一行的步态指标                 │ 复合主键 (run_id, leg) │
└──────────────┴──────────┴────────────────────────────────────┴────────────────────────┘

设计决策（AI警告！！！！！）

奖励项用 EAV，机器人配置用宽表

奖励项是会变的集合 —— R8 加 air_time_excess、R12 把 dof_acc_l2 拆三项、R16 又全关。
每加一项就 ALTER TABLE 加一列，跑到第三十轮表里一半是空列。

判断法则：属性固定且都会用到 → 宽表；属性稀疏或会增删 → EAV。两种在同一设计里并存。

范式到 3NF 打住，且有意反范式化

runs 里的 kp / kd / 默认角严格说该拆 configs 表，但不拆：
每轮配置几乎都不同（拆了行数一样多）、历史配置永不修改（无更新异常）、几乎每次查询都要用。

判断标准不是「符不符合范式」，是「会不会产生更新/插入/删除三种异常」。不会就别拆。

数据通过 git 同步，不走 MySQL 直连

离线可用 / 有版本历史 / 天然异地备份 / 不暴露数据库端口。

体积不是问题：一轮入库约 1.8 KB，每天 3 轮跑两个月约 324 KB，
git 打包压缩后不到 1 MB。

⚠ 这个结论的前提是 --skip-extended-insert —— 没有它，新增一行会让整条
INSERT 语句改变，delta 压缩失效，同样的数据会膨胀到近 10 MB。

规则：git 里只放文本。 .pt / .mp4 / tfevents 一律不进。

migration 只增不改

不改的是 migration 文件，不是数据。 数据随便 UPDATE。

违反后果特别隐蔽：改了 002 加一列，CREATE TABLE IF NOT EXISTS 发现表已存在
直接跳过，新列根本没加，还不报错 —— 两台机器分叉且无人提醒。

要改结构就新建 007_xxx.sql 写 ALTER TABLE。

⚠ MySQL 没有 ADD COLUMN IF NOT EXISTS（PostgreSQL 有）。setup.sh 靠
2>/dev/null || 提示 容错，代价是真语法错误也会被吞掉 ——
所以新 migration 第一次必须单独跑一遍看输出。

类型选择（AI建议）

- DECIMAL 不用 FLOAT —— 权重跨七个数量级（-10.0 到 -4.0e-8），
  浮点存 0.25 是近似值，WHERE weight = -0.25 会查不到。用 DECIMAL(16,12)。
  SQL 里也不要写科学计数法，-2.5e-7 会先过一道浮点，手写成 -0.000000250000。
- DATETIME 不用 TIMESTAMP —— 后者做时区转换且有 2038 上限。
- air_s 允许 NULL 而非填 0 —— 探针的 n/a（一次没离地）与「腾空 0 秒」是两回事，
  混用会让 AVG 算错。NULL 在聚合函数里是被跳过的，正是想要的行为。
- leg 用 VARCHAR(8) 而非 ENUM —— ENUM 把四足写死，进来六足/双足要 ALTER。

外键（外码）：删除方向相反

runs → robots         ON DELETE RESTRICT   删机器人：拒绝
reward_terms → runs   ON DELETE CASCADE    删跑次：明细跟着删
gait_probe   → runs   ON DELETE CASCADE

备忘法则：子行离开父行还有没有意义。有就 RESTRICT，没有就 CASCADE。

训练记录离开机器人型号仍是独立观测（护栏卡住）；奖励项离开跑次无用。

索引

(term_name, run_id) 是故意跟主键 (run_id, term_name) 反着来的。

最左前缀原则：(a, b) 的索引能加速「按 a 查」和「按 a+b 查」，
不能解决「只按 b 查」。而「某个奖励项跨轮次怎么变的」正是本库最核心的问题。

常用查询

跨轮次对比步态：

SELECT r.label, r.kp, r.kd, r.mean_action_std, r.gait_consistency,
       ROUND(AVG(g.duty),4) AS duty_avg,
       ROUND(MAX(g.duty)/MIN(g.duty),3) AS duty_ratio,
       r.change_summary, r.verdict
FROM runs r
LEFT JOIN gait_probe g ON g.run_id = r.run_id
GROUP BY r.run_id
ORDER BY r.started_at;

追踪单个奖励项的演化：

SELECT r.label, t.weight, t.measured
FROM reward_terms t
JOIN runs r ON r.run_id = t.run_id
WHERE t.term_name = 'feet_slide'
ORDER BY r.started_at;

LEFT JOIN 的 LEFT 是必须的 —— 训练完还没跑探针的轮次，用普通 JOIN 会整行消失。

目录

migrations/   建库建表，按编号顺序执行（编号补零到三位，保证字典序＝执行序）
seed/         基础数据（机器人型号），幂等
scripts/      setup / dump / restore
data/         dump.sql，数据的唯一 git 载体
