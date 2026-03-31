# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code configuration directory** - a personalized setup for running Claude Code with custom settings. It is not an application project with source code, but rather a configuration workspace.

## Configuration

- **Config directory**: `.claude/` (set via `.envrc`)
- **Settings**: `.claude/settings.json`
- **Model**: Uses `minimax-m25` model (configured for all model tiers: haiku, sonnet, opus)
- **API endpoint**: Custom endpoint at `http://106.75.235.251:9000`
- **API key**: Configured via `ANTHROPIC_API_KEY` in `.envrc`

## Commands

No standard development commands (build, lint, test) apply to this configuration directory. This is a Claude Code configuration workspace - all interactions should be with Claude Code itself.

## Architecture

The `.claude/` directory contains:

- **`settings.json`** - Main Claude Code configuration (model, API settings)
- **`settings.local.json`** - Local user overrides
- **`plugins/`** - Claude Code plugins from the official marketplace
  - `marketplaces/claude-plugins-official/` - Official plugin marketplace
  - Various installed plugins for different development tasks
## Rules

### ⚠️ 重要：OpenClaw 操作必须在 Docker 容器内执行
- **禁止**在主机（macOS）上运行 `openclaw` CLI
- 所有 OpenClaw 操作（channels add、gateway、agent 等）应通过：`docker compose -f deploy/docker-compose.yml --env-file .env exec openclaw openclaw <command>`
- 主机 OpenClaw CLI 缺少 Matrix 相关依赖时，可能导致插件失败
- 日志：`docker compose -f deploy/docker-compose.yml --env-file .env logs -f openclaw`

- Always use Context7 when I need library/API documentation, code generation, setup or configuration steps without me having to explicitly ask.
- Follow industry best practices for every task:
  - Docker Compose: official best practices, healthcheck, depends_on with condition: service_healthy
  - Shell scripts: set -euo pipefail, shellcheck linting
  - Security: CIS Docker Benchmark, OWASP guidelines
  - Architecture: 12-Factor App principles
  - Backup: 3-2-1 rule (3 copies, 2 media, 1 offsite)


## Project Status

**2026-03-30**: All SPECs (001-023) completed.

| Service | Status | Port |
|---------|--------|------|
| Tuwunel (Matrix HS) | ✅ healthy | 127.0.0.1:8008 |
| Matrix 客户端 | — | 自备（连接 Tuwunel） |
| OpenClaw Agent Manager | ✅ healthy | container |
| OpenClaw Agent Dev | ✅ healthy | container |

**Architecture**: OpenClaw Agent is Gateway-first (not traditional Matrix bot)
- Matrix channel for notifications
- Commands via Gateway RPC (`openclaw agent` explicit invocation)
- Session management is explicit, no auto-response to @mention

## Notes

- This directory is configured to use a custom (non-Antrophic) API endpoint
- The `ANTHROPIC_API_KEY` in `.envrc` is specific to this setup
- This configuration uses `minimax-m25` as the default model
