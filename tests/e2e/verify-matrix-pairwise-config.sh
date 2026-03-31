#!/usr/bin/env bash
# 校验 openclaw.json：各 agent 绑定同一团队房、mentionPatterns 齐全，满足「两两 @」路由前提。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
JSON="${OPENCLAW_JSON:-$ROOT/volumes/openclaw/openclaw.json}"
ROLES=(arch dev manager qa sre research)

if [[ ! -f "$JSON" ]]; then
  echo "verify-matrix-pairwise-config: 缺少 $JSON（可设 OPENCLAW_JSON）" >&2
  exit 1
fi

export VERIFY_MATRIX_JSON="$JSON"
export VERIFY_MATRIX_ROLES="${ROLES[*]}"
node <<'NODE'
const fs = require("fs");
const path = process.env.VERIFY_MATRIX_JSON;
const ROLES = (process.env.VERIFY_MATRIX_ROLES || "").trim().split(/\s+/).filter(Boolean);
const c = JSON.parse(fs.readFileSync(path, "utf8"));
const errors = [];

const roomFromBindings = new Map();
for (const b of c.bindings || []) {
  const id = b.agentId;
  const peer = b.match && b.match.peer;
  if (!peer || peer.kind !== "group" || !peer.id) continue;
  roomFromBindings.set(id, peer.id);
}

let roomId = null;
for (const r of ROLES) {
  const rid = roomFromBindings.get(r);
  if (!rid) errors.push("binding 缺失: " + r);
  else if (!roomId) roomId = rid;
  else if (rid !== roomId) errors.push("团队房不一致: " + r + " -> " + rid + " (期望 " + roomId + ")");
}

const mx = c.channels && c.channels.matrix;
const g = mx && mx.groups;
if (roomId && (!g || !g[roomId])) {
  errors.push("channels.matrix.groups 未包含团队房 " + roomId);
} else if (roomId && g[roomId] && g[roomId].requireMention !== true) {
  errors.push("团队房 requireMention 应为 true");
} else if (roomId && g[roomId] && g[roomId].allowBots !== "mentions") {
  errors.push("团队房 allowBots 应为 \"mentions\"（bot 间仅在被 @ 时触发）");
}
if (mx && mx.enabled !== false && mx.groupPolicy !== "allowlist") {
  errors.push("channels.matrix.groupPolicy 应为 allowlist");
}

if (roomId && mx && mx.accounts && typeof mx.accounts === "object") {
  for (const r of ROLES) {
    const acc = mx.accounts[r];
    if (!acc || typeof acc !== "object") {
      errors.push("Matrix 账号 " + r + " 缺失或无效");
      continue;
    }
    if (acc.groupPolicy !== "allowlist") {
      errors.push("Matrix 账号 " + r + " 的 groupPolicy 应为 allowlist");
    }
    const ag = acc.groups && acc.groups[roomId];
    if (!ag) {
      errors.push("Matrix 账号 " + r + " 缺少 groups." + roomId + "（须与团队房 requireMention 对齐）");
    } else {
      if (ag.requireMention !== true) errors.push("Matrix 账号 " + r + " 团队房 requireMention 应为 true");
      if (ag.allowBots !== "mentions") errors.push("Matrix 账号 " + r + " 团队房 allowBots 应为 mentions");
    }
  }
}

const list = (c.agents && c.agents.list) || [];
for (const r of ROLES) {
  const a = list.find((x) => x.id === r);
  if (!a) {
    errors.push("agents.list 缺少: " + r);
    continue;
  }
  const p = a.groupChat && a.groupChat.mentionPatterns;
  if (!Array.isArray(p) || p.length < 3) {
    errors.push(r + " mentionPatterns 异常");
    continue;
  }
  const joined = p.join(" ");
  if (!joined.includes("@" + r + ":")) {
    errors.push(r + " mentionPatterns 应含 @" + r + ":<server>");
  }
}

if (errors.length) {
  console.error("verify-matrix-pairwise-config: FAILED");
  for (const e of errors) console.error("  - " + e);
  process.exit(1);
}
console.log("verify-matrix-pairwise-config: OK (room=" + roomId + ", agents=" + ROLES.length + ")");
NODE
