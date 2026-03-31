.PHONY: help deploy fresh build up down logs ps test test-smoke test-e2e test-integration uv-sync clean guard-env sync-synapse-config e2e-matrix e2e-matrix-all stack-check

DC := docker compose -f deploy/docker-compose.yml --env-file .env

guard-env:
	@test -f .env || (echo "缺少 .env。请: cp .env.example .env 并编辑，或运行 ./platform/deploy.sh"; exit 1)

help:
	@echo "Claw Team — AI 软件研发工厂 (MVP)"
	@echo ""
	@echo "推荐（每次干净环境）:"
	@echo "  make fresh       - 清空 volumes + 重新 build/up（等同 deploy.sh --fresh）"
	@echo ""
	@echo "其他:"
	@echo "  ./platform/deploy.sh  - 保留现有 volumes，仅 build + up + 健康检查"
	@echo ""
	@echo "常用命令（需先有 .env）:"
	@echo "  make deploy      - 等同 ./platform/deploy.sh（不删数据）"
	@echo "  make fresh       - 等同 ./platform/deploy.sh --fresh"
	@echo "  make build       - 构建镜像"
	@echo "  make up          - 启动（会先 build）"
	@echo "  make down        - 停止"
	@echo "  make restart     - 重启"
	@echo "  make logs        - 跟踪日志"
	@echo "  make ps          - 服务状态"
	@echo "  make uv-sync     - uv sync（Python 依赖）"
	@echo "  make test        - 全部测试（pytest）"
	@echo "  make test-smoke  - 仅 smoke 用例（pytest -m smoke）"
	@echo "  make test-e2e    - 同 make test"
	@echo "  make clean       - 停止并删除卷数据（慎用）"
	@echo "  make stack-check   - 检查 tuwunel/openclaw 容器与团队房文件"
	@echo "  make e2e-matrix    - Matrix mention 核心 E2E（human→@manager，推荐 CI）"
	@echo "  make e2e-matrix-all - 另跑 manager→@dev（耗时长，易因 LLM/队列失败）"

deploy:
	@bash platform/deploy.sh

fresh: guard-env
	@bash platform/deploy.sh --fresh

sync-synapse-config: guard-env
	@echo "sync-synapse-config: 已弃用（当前 Homeserver 为 Tuwunel，无需 homeserver.yaml）。"

build: guard-env
	$(DC) build

# 与 make deploy 相同：先 Tuwunel → 同步账号 → 再 OpenClaw（避免无团队房、无 token）
up: guard-env
	@bash platform/deploy.sh
	@echo ""
	@echo "  Matrix (Tuwunel): http://127.0.0.1:8008（若改了 SYNAPSE_PORT 请以 .env 为准）"

down:
	$(DC) down

restart: down up

logs:
	$(DC) logs -f

ps:
	$(DC) ps

uv-sync:
	uv sync

test: guard-env
	uv run pytest tests/

test-smoke: guard-env
	uv run pytest tests/ -m smoke

test-e2e: test

test-integration: test

stack-check: guard-env
	@bash platform/stack-check.sh

# Matrix：栈 + openclaw.json + human→@manager（验证 mention 出站；需真实 LLM）
e2e-matrix: guard-env
	@bash matrix/e2e-matrix-agents-core.sh

# 完整：另测 manager Matrix 账号 @dev（agent 间；易超时）
e2e-matrix-all: guard-env
	@bash matrix/e2e-matrix-agents-all.sh

clean: guard-env
	$(DC) down -v
	rm -rf volumes/*/
