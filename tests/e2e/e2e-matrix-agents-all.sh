#!/usr/bin/env bash
# 完整：core + manager@dev（agent 间 mention；依赖 LLM 与 Gateway 空闲，易超时，见 make e2e-matrix-all 说明）。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$ROOT/tests/e2e/e2e-matrix-agents-core.sh"
sleep 60
bash "$ROOT/tests/e2e/e2e-matrix-manager-ping-dev.sh"
echo "e2e-matrix-agents-all: 全部通过（含 manager→@dev）"
