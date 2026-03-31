#!/usr/bin/env bash
# 历史脚本：当前栈使用 Tuwunel（无需 homeserver.yaml）。若仍需 Synapse，请自行维护镜像与卷。
set -euo pipefail
echo "sync-synapse-config: 跳过（Homeserver 已为 Tuwunel，见 deploy/docker-compose.yml）。" >&2
exit 0
