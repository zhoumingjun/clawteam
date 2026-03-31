#!/usr/bin/env bash
# 稳定子集：栈检查 + openclaw.json 校验 + human@manager mention E2E（不跑 agent→agent，避免 LLM 队列/路由导致长超时失败）。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash "$ROOT/platform/stack-check.sh"
bash "$ROOT/matrix/verify-matrix-pairwise-config.sh"
bash "$ROOT/matrix/e2e-matrix-mentions.sh"
echo "e2e-matrix-agents-core: 全部通过（含 human 触发、多账号 mention 出站）"
