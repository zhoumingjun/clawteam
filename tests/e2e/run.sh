#!/bin/bash
# 兼容旧入口：与 make test 相同（pytest tests/）
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

if [ ! -f .env ]; then
  echo "[test] 缺少 .env：请先 cp .env.example .env 并编辑"
  exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "[test] 需要安装 uv：https://docs.astral.sh/uv/"
  exit 1
fi

uv sync
exec uv run pytest tests/ "$@"
