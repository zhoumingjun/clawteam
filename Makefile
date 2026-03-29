.PHONY: build up down logs ps test-smoke test-e2e clean help

# 默认目标
help:
	@echo "Claw Team - AI 软件研发工厂"
	@echo ""
	@echo "可用命令："
	@echo "  make build       - 构建所有 Docker 镜像"
	@echo "  make up          - 启动所有服务"
	@echo "  make down        - 停止所有服务"
	@echo "  make restart     - 重启所有服务"
	@echo "  make logs        - 查看所有日志"
	@echo "  make ps          - 查看服务状态"
	@echo "  make test-smoke  - 运行烟雾测试"
	@echo "  make test-e2e    - 运行 E2E 测试"
	@echo "  make clean       - 清理容器和卷"

# 构建所有镜像
build:
	docker compose build

# 启动所有服务
up:
	docker compose up -d
	@echo "服务已启动"
	@echo "Conduit (Matrix): http://localhost:10000"
	@echo "Element Web: http://localhost:10001"

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
