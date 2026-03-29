.PHONY: help dev test build run clean lint fmt

# 默认目标
help:
	@echo "Todo Demo - 开发命令"
	@echo ""
	@echo "可用命令:"
	@echo "  make dev      - 启动本地开发服务器"
	@echo "  make test     - 运行测试"
	@echo "  make build    - 构建生产版本"
	@echo "  make run      - 运行生产版本"
	@echo "  make clean    - 清理临时文件"
	@echo "  make lint     - 代码检查"

# 开发服务器 (使用 npx serve)
dev:
	@echo "启动开发服务器..."
	@npx -y serve src -l 3000

# 运行测试
test:
	@echo "运行测试..."
	@cd tests && npx jest --coverage

# 构建生产版本
build:
	@echo "构建生产版本..."
	@mkdir -p dist
	@cp -r src/* dist/
	@echo "构建完成: dist/"

# 运行生产版本
run:
	@echo "运行生产服务器..."
	@npx -y serve dist -l 3000

# 清理临时文件
clean:
	@echo "清理临时文件..."
	@rm -rf dist/
	@rm -rf tests/coverage/
	@rm -rf node_modules/
	@echo "清理完成"

# 代码检查
lint:
	@echo "代码检查..."
	@npx -y eslint src/

# 格式化代码
fmt:
	@echo "格式化代码..."
	@npx -y prettier --write src/**/*.js

# 安装依赖
install:
	@echo "安装依赖..."
	@npm install
