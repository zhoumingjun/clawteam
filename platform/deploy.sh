#!/bin/bash
# 一键部署 MVP：检查 .env → 数据目录 → build & up → 等待 Tuwunel 健康
# 用法: ./platform/deploy.sh           # 保留现有 volumes 数据
#       ./platform/deploy.sh --fresh  # 停止服务并清空 volumes（干净重来）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
COMPOSE=(docker compose -f deploy/docker-compose.yml --env-file .env)

info() { echo "[deploy] $*"; }
err() { echo "[deploy] ERROR: $*" >&2; }

FRESH=0
for arg in "$@"; do
  case "$arg" in
    --fresh|-f) FRESH=1 ;;
    -h|--help)
      echo "用法: $0 [--fresh|-f]"
      echo "  --fresh  先 docker compose down -v，再删除 volumes/tuwunel-data 与 volumes/openclaw，然后重新部署"
      exit 0
      ;;
  esac
done

if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    err "已从 .env.example 创建 .env，请编辑填写 API Key 与各账号密码后重新运行："
    err "  $0"
    exit 1
  fi
  err "缺少 .env，请先创建（可参考 .env.example）"
  exit 1
fi

# 不 source .env（值里可能含空格/特殊字符）；端口用安全解析
SYNAPSE_PORT="$(
  python3 -c "
from pathlib import Path
for line in Path('.env').read_text(encoding='utf-8').splitlines():
    s = line.strip()
    if s.startswith('SYNAPSE_PORT='):
        v = s.split('=', 1)[1].strip().strip('\"').strip(\"'\")
        print(v)
        break
else:
    print('8008')
"
)"
export SYNAPSE_PORT

if [ "$FRESH" -eq 1 ]; then
  info "干净重来：停止容器并清空本地卷数据（Tuwunel DB、OpenClaw 状态将丢失）…"
  "${COMPOSE[@]}" down -v 2>/dev/null || true
  rm -rf "${ROOT}/volumes/tuwunel-data" "${ROOT}/volumes/openclaw" "${ROOT}/volumes/synapse-data"
  mkdir -p "${ROOT}/volumes/tuwunel-data" "${ROOT}/volumes/openclaw"
fi

mkdir -p volumes/tuwunel-data volumes/openclaw

# 分两段启动：若 Homeserver 与 OpenClaw 同时 up，OpenClaw 可能在账号尚未创建前 bootstrap
info "启动 Tuwunel（OpenClaw 在密码同步后再启动）…"
"${COMPOSE[@]}" up -d --build tuwunel

info "等待 Matrix Client-Server API 就绪..."
for i in $(seq 1 120); do
  if curl -sf "http://127.0.0.1:${SYNAPSE_PORT:-8008}/_matrix/client/versions" >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 120 ]; then
    err "Tuwunel 在 127.0.0.1:${SYNAPSE_PORT:-8008} 未就绪，请查看: docker compose -f deploy/docker-compose.yml logs tuwunel"
    exit 1
  fi
  sleep 1
done

info "将 .env 中的 Matrix 密码写入 homeserver（创建缺失用户；已存在用户不会改密）…"
bash "${ROOT}/matrix/sync-all-matrix-passwords.sh"

info "启动 OpenClaw…"
"${COMPOSE[@]}" up -d --build openclaw

info "完成。"
echo ""
echo "  Matrix（Element 连接）: http://127.0.0.1:${SYNAPSE_PORT:-8008}  [Tuwunel]"
echo "  Human 账号与密码: 见 .env 中 HUMAN_USERNAME、HUMAN_PASSWORD（MXID 域名为 SYNAPSE_SERVER_NAME）"
echo "  查看 OpenClaw 日志: docker compose -f deploy/docker-compose.yml logs -f openclaw"
echo "  在容器内执行 openclaw: docker compose -f deploy/docker-compose.yml exec openclaw openclaw --help"
echo ""
echo "首次启动时容器会注册 Matrix 账号、拉起 Gateway、写入 ./volumes/openclaw/；Agent 在房间内 @manager 等即可协作。"
