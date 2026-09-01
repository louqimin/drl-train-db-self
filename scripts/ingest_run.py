#~/drl-train-db-self/scripts/ingest_run.py:

#!/usr/bin/env python3
"""把一轮 Isaac Lab 训练的产物转成 SQL。只生成，不连库。

用法:
  python scripts/ingest_run.py <run_dir> --label R16 [--verdict 达标] > /tmp/r16.sql
"""
import argparse, json, re, sys
from pathlib import Path

import yaml
from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

TAIL = 20   # 末 N 点均值。单点不可用：Episode_Reward/* 只在有回合结束的迭代更新

LEGS = ("FL", "FR", "RL", "RR")
JOINTS = [f"{leg}_{j}_JOINT" for leg in LEGS for j in ("ABAD", "HIP", "KNEE")]

METRIC_TAGS = {
    "mean_reward":     "Train/mean_reward",
    "episode_length":  "Train/mean_episode_length",
    "mean_action_std": "Policy/mean_std",
    "error_vel_xy":    "Metrics/base_velocity/error_vel_xy",
    "error_vel_yaw":   "Metrics/base_velocity/error_vel_yaw",
    "base_contact":    "Episode_Termination/base_contact",
}


def q(s):
    """SQL 字符串字面量。None -> NULL。"""
    if s is None:
        return "NULL"
    return "'" + str(s).replace("\\", "\\\\").replace("'", "''") + "'"


def dec(v, places=12):
    """SQL 数值字面量。绝不输出科学计数法——那会先过一道浮点，
    抵消 DECIMAL 的意义。DECIMAL(16,12) 的下限是 1e-12。"""
    if v is None:
        return "NULL"
    return f"{float(v):.{places}f}"


def resolve_joint(joint_pos, name):
    """joint_pos 的键是正则。Isaac Lab 用 fullmatch 且拒绝歧义（见 D20）。"""
    for pat, val in joint_pos.items():
        if re.fullmatch(pat, name):
            return float(val)
    return None


def read_env(run_dir):
    p = run_dir / "params" / "env.yaml"
    # safe_load 会拒绝 !!python/tuple 与 !!python/object/apply。
    # 文件是我们自己训练产出的，不是外来输入。
    return yaml.unsafe_load(p.read_text())


def read_scalars(run_dir):
    ea = EventAccumulator(str(run_dir), size_guidance={"scalars": 0})
    ea.Reload()
    have = set(ea.Tags()["scalars"])

    def tail_mean(tag):
        if tag not in have:
            return None
        vals = [e.value for e in ea.Scalars(tag)][-TAIL:]
        return sum(vals) / len(vals) if vals else None

    metrics = {k: tail_mean(t) for k, t in METRIC_TAGS.items()}
    measured = {
        t.split("/", 1)[1]: tail_mean(t)
        for t in have
        if t.startswith("Episode_Reward/")
    }
    return metrics, measured


def read_checkpoints(run_dir):
    nums = [int(m.group(1))
            for f in run_dir.glob("model_*.pt")
            if (m := re.fullmatch(r"model_(\d+)\.pt", f.name))]
    return (max(nums) + 1) if nums else None


def extract_rewards(cfg):
    """{项名: (权重, 参数)}。params 只留标量——sensor_cfg 里有 slice 对象，
    json.dumps 会抛 TypeError，而它每轮都一样、从不作为查询条件。"""
    out = {}
    for name, spec in (cfg.get("rewards") or {}).items():
        if not isinstance(spec, dict):
            continue
        flat = {k: v for k, v in (spec.get("params") or {}).items()
                if isinstance(v, (int, float, str, bool))}
        out[name] = (spec.get("weight"), flat or None)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run_dir")
    ap.add_argument("--robot-id", default="d1_edu")
    ap.add_argument("--label")
    ap.add_argument("--git-commit", help="训练时刻的 commit。事后补记一律留空——"
                                         "填今天的 HEAD 就是个假答案")
    ap.add_argument("--change-summary")
    ap.add_argument("--verdict")
    ap.add_argument("--notes")
    ap.add_argument("--gait-json", help="探针输出的 json（探针加 --json 之后才有）")
    a = ap.parse_args()

    run_dir = Path(a.run_dir).expanduser().resolve()
    if not run_dir.is_dir():
        sys.exit(f"目录不存在: {run_dir}")

    cfg = read_env(run_dir)
    metrics, measured = read_scalars(run_dir)
    iters = read_checkpoints(run_dir)
    rewards = extract_rewards(cfg)

    art = cfg["scene"]["robot"]
    jp = art["init_state"]["joint_pos"]
    actuators = art.get("actuators") or {}
    act = next(iter(actuators.values())) if actuators else {}
    kp, kd = act.get("stiffness"), act.get("damping")

    defaults = {n: resolve_joint(jp, n) for n in JOINTS}

    action_scale = None
    for spec in (cfg.get("actions") or {}).values():
        if isinstance(spec, dict) and "scale" in spec:
            action_scale = spec["scale"]

    num_envs = (cfg.get("scene") or {}).get("num_envs")
    ep_s = cfg.get("episode_length_s")

    max_iters = None
    ag = run_dir / "params" / "agent.yaml"
    if ag.exists():
        max_iters = (yaml.unsafe_load(ag.read_text()) or {}).get("max_iterations")


    started = re.sub(r"^(\d{4})-(\d\d)-(\d\d)_(\d\d)-(\d\d)-(\d\d)$",
                     r"\1-\2-\3 \4:\5:\6", run_dir.name)

    # ---- 自检：奖励项之和 × 回合时长 vs mean_reward（两条独立代码路径）----
    total = sum(v for v in measured.values() if v is not None)
    print(f"-- 自检: Σ Episode_Reward = {total:.6f}"
          f"  episode_length_s = {ep_s}"
          f"  Train/mean_reward = {metrics['mean_reward']}", file=sys.stderr)
    if ep_s and metrics["mean_reward"]:
        print(f"--       Σ×时长 = {total * float(ep_s):.4f}"
              f"  比值 = {total * float(ep_s) / metrics['mean_reward']:.4f}（应≈1）",
              file=sys.stderr)

    # ---- 生成 SQL ----
    cols = {
        "robot_id": q(a.robot_id),
        "label": q(a.label),
        "run_dir": q(run_dir.name),
        "started_at": q(started),
        "git_commit": q(a.git_commit),
        "kp": dec(kp, 4), "kd": dec(kd, 4),
        "default_abad": dec(defaults["FL_ABAD_JOINT"], 4),
        "default_hip_front": dec(defaults["FL_HIP_JOINT"], 4),
        "default_hip_rear": dec(defaults["RL_HIP_JOINT"], 4),
        "default_knee": dec(defaults["FL_KNEE_JOINT"], 4),
        "action_scale": dec(action_scale, 4),
        


        "num_envs": str(num_envs) if num_envs is not None else "NULL",
        "max_iterations": str(max_iters) if max_iters is not None else "NULL",
        "completed": "TRUE" if (iters and max_iters and iters >= max_iters) else "FALSE",
        
        "iterations_done": str(iters) if iters is not None else "NULL",


        
        "mean_reward": dec(metrics["mean_reward"], 6),
        "episode_length": dec(metrics["episode_length"], 3),
        "mean_action_std": dec(metrics["mean_action_std"], 6),
        "error_vel_xy": dec(metrics["error_vel_xy"], 6),
        "error_vel_yaw": dec(metrics["error_vel_yaw"], 6),
        "base_contact": dec(metrics["base_contact"], 6),
        "gait_consistency": "NULL",
        "change_summary": q(a.change_summary),
        "verdict": q(a.verdict),
        "notes": q(a.notes),
    }

    print("USE drl_train;")
    print("START TRANSACTION;")
    print(f"INSERT INTO runs ({', '.join(cols)})")
    print(f"VALUES ({', '.join(cols.values())});")
    print("SET @rid = LAST_INSERT_ID();")

    rows = []
    for name in sorted(set(rewards) | set(measured)):
        w, p = rewards.get(name, (None, None))
        rows.append(f"  (@rid, {q(name)}, {dec(w)}, "
                    f"{q(json.dumps(p, sort_keys=True)) if p else 'NULL'}, "
                    f"{dec(measured.get(name))})")
    if rows:
        print("INSERT INTO reward_terms (run_id, term_name, weight, params, measured) VALUES")
        print(",\n".join(rows) + ";")

    if a.gait_json:
        g = json.loads(Path(a.gait_json).read_text())
        grows = [f"  (@rid, {q(leg)}, {dec(d.get('duty'),6)}, {dec(d.get('air_s'),6)}, "
                 f"{dec(d.get('contact_s'),6)}, {dec(d.get('clearance_avg'),6)}, "
                 f"{dec(d.get('slide'),6)}, {dec(d.get('period_s'),6)})"
                 for leg, d in sorted(g.items())]
        print("INSERT INTO gait_probe (run_id, leg, duty, air_s, contact_s, "
              "clearance_avg, slide, period_s) VALUES")
        print(",\n".join(grows) + ";")

    print("COMMIT;")


if __name__ == "__main__":
    main()
