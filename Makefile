.PHONY: help build up down logs ps test-smoke test-e2e clean init-user init-check init-openclaw-agent help

# 默认目标
help:
	@echo "Claw Team - AI 软件研发工厂"
	@echo ""
	@echo "可用命令："
	@echo "  make up          - 启动所有服务"
	@echo "  make down        - 停止所有服务"
	@echo "  make restart     - 重启所有服务"
	@echo "  make logs        - 查看所有日志"
	@echo "  make ps          - 查看服务状态"
	@echo "  make init-user   - 初始化 Matrix 用户"
	@echo "  make init-check  - 检查初始化状态"
	@echo "  make init-openclaw-agent - 初始化 OpenClaw Agent"
	@echo "  make test-smoke  - 运行烟雾测试"
	@echo "  make test-e2e    - 运行 E2E 测试"
	@echo "  make clean       - 清理容器和卷"

# 启动所有服务
up:
	docker compose up -d
	@echo ""
	@echo "服务已启动："
	@echo "  Synapse API: http://localhost:8008"
	@echo "  Element Web: http://localhost:10001"

# 停止所有服务
down:
	docker compose down

# 重启所有服务
restart: down up

# 查看日志
logs:
	docker compose logs -f

# 查看服务状态
ps:
	docker compose ps

# 检查初始化状态
init-check:
	@echo "检查初始化状态..."
	@echo ""
	@echo "请设置以下环境变量（必需）："
	@echo "  export MANAGER_PASSWORD=xxx"
	@echo "  export HUMAN_PASSWORD=xxx"
	@echo "  export ARCH_PASSWORD=xxx"
	@echo "  export DEV_PASSWORD=xxx"
	@echo "  export QA_PASSWORD=xxx"
	@echo "  export SRE_PASSWORD=xxx"
	@echo "  export RESEARCH_PASSWORD=xxx"
	@echo "  export OPENCLAW_API_KEY=xxx"
	@echo "  export OPENCLAW_AGENT_PASSWORD=xxx"
	@echo ""
	@echo "或复制 .env.example 为 .env 并填写密码"

# 初始化 Matrix 用户
init-user: init-check
	@echo ""
	@echo "开始初始化 Matrix 用户..."
	@bash configs/matrix/init.sh

# 初始化 OpenClaw Agent
init-openclaw-agent:
	@echo ""
	@echo "开始初始化 OpenClaw Agent Manager..."
	@bash scripts/openclaw-agent-init.sh

# 烟雾测试
test-smoke:
	@echo "运行烟雾测试..."
	@bash tests/smoke/run.sh

# E2E 测试
test-e2e:
	@echo "运行 E2E 测试..."
	@bash tests/e2e/run.sh

# 清理
clean:
	docker compose down -v
	rm -rf volumes/*/
