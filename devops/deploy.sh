#!/bin/bash
# 一键部署：检查 .env → 数据目录 → build & up → 等待健康
# 用法: ./devops/deploy.sh           # 保留数据
#       ./devops/deploy.sh --fresh   # 清空 volumes 后重建
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
DC=(docker compose -f containers/docker-compose.yml --env-file .env)

info() { echo "[deploy] $*"; }
err()  { echo "[deploy] ERROR: $*" >&2; }

FRESH=0
for arg in "$@"; do
  case "$arg" in
    --fresh|-f) FRESH=1 ;;
    -h|--help) echo "用法: $0 [--fresh|-f]"; exit 0 ;;
  esac
done

if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    err "已创建 .env，请编辑填写 ANTHROPIC_API_KEY 后重新运行"
    exit 1
  fi
  err "缺少 .env"; exit 1
fi

# 安全解析端口（不 source .env）
MATRIX_PORT="$(grep -m1 '^MATRIX_PORT=' .env 2>/dev/null | cut -d= -f2 | tr -d '[:space:]"'"'"'" || echo 8008)"
MATRIX_PORT="${MATRIX_PORT:-8008}"

if [ "$FRESH" -eq 1 ]; then
  info "干净重来：停止容器并清空卷数据..."
  "${DC[@]}" down -v 2>/dev/null || true
  rm -rf "${ROOT}/volumes/tuwunel-data" "${ROOT}/volumes/openclaw"
fi

mkdir -p volumes/tuwunel-data volumes/openclaw

info "启动服务..."
"${DC[@]}" up -d --build

info "等待 Tuwunel 就绪..."
for i in $(seq 1 60); do
  if curl -sf "http://127.0.0.1:${MATRIX_PORT}/_matrix/client/versions" >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 60 ]; then
    err "Tuwunel 未就绪，请查看: ${DC[*]} logs tuwunel"
    exit 1
  fi
  sleep 2
done

info "完成。"
echo ""
echo "  Matrix: http://127.0.0.1:${MATRIX_PORT}"
echo "  日志:   ${DC[*]} logs -f openclaw"
echo ""
