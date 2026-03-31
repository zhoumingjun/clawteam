#!/bin/bash
# 启动 OpenClaw Gateway

start_gateway() {
  if openclaw health >/dev/null 2>&1; then
    log_info "Gateway 已在运行"
    return 0
  fi
  log_info "启动 OpenClaw Gateway..."
  nohup openclaw gateway run --port "${OPENCLAW_PORT:-18789}" --allow-unconfigured >/tmp/gateway.log 2>&1 &
  local i=1
  while [ "$i" -le 45 ]; do
    if openclaw health >/dev/null 2>&1; then
      log_info "Gateway 就绪"
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  log_warn "Gateway 启动超时，请检查 /tmp/gateway.log"
  return 1
}
