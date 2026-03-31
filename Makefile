.PHONY: help deploy fresh build up down restart logs ps test test-smoke test-e2e test-integration uv-sync clean guard-env stack-check e2e-matrix e2e-matrix-all dashboard-dev

DC := docker compose -f containers/docker-compose.yml --env-file .env

guard-env:
	@test -f .env || (echo "缺少 .env。请: cp .env.example .env 并编辑"; exit 1)

help:
	@echo "Claw Team — AI 软件研发工厂"
	@echo ""
	@echo "  make fresh       - 推荐：清空 volumes + 重新部署"
	@echo "  make deploy      - 保留数据，build + up + 健康检查"
	@echo "  make up          - 启动"
	@echo "  make down        - 停止"
	@echo "  make restart     - 重启"
	@echo "  make logs        - 日志"
	@echo "  make ps          - 状态"
	@echo "  make test        - 全部测试（pytest）"
	@echo "  make test-smoke  - 仅 smoke 用例"
	@echo "  make stack-check - 健康检查"
	@echo "  make e2e-matrix  - Matrix E2E 测试"
	@echo "  make clean       - 停止并删除卷（慎用）"

deploy: guard-env
	@bash devops/deploy.sh

fresh: guard-env
	@bash devops/deploy.sh --fresh

build: guard-env
	$(DC) build

up: guard-env
	@bash devops/deploy.sh

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
	@bash devops/stack-check.sh

e2e-matrix: guard-env
	@bash tests/e2e/e2e-matrix-agents-core.sh

e2e-matrix-all: guard-env
	@bash tests/e2e/e2e-matrix-agents-all.sh

clean: guard-env
	$(DC) down -v
	rm -rf volumes/*/

dashboard-dev:
	cd dashboard && OPENCLAW_DATA_DIR=../volumes/openclaw npm run dev
