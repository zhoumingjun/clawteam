#!/bin/bash
# 烟雾测试脚本

set -e

echo "=== Claw Team 烟雾测试 ==="
echo ""

# 测试 1: 检查 Docker 是否可用
echo "[1/10] 检查 Docker..."
docker --version > /dev/null 2>&1 || { echo "FAIL: Docker 不可用"; exit 1; }
echo "PASS"

# 测试 2: 检查 docker-compose 是否可用
echo "[2/10] 检查 docker-compose..."
docker compose version > /dev/null 2>&1 || { echo "FAIL: docker-compose 不可用"; exit 1; }
echo "PASS"

# 测试 3: 检查服务是否启动
echo "[3/10] 检查服务状态..."
docker compose ps | grep -q "Up" || { echo "FAIL: 服务未启动"; exit 1; }
echo "PASS"

# 测试 4: Conduit 健康检查
echo "[4/10] 检查 Conduit..."
curl -s http://localhost:10000/_matrix/client/versions > /dev/null 2>&1 || { echo "FAIL: Conduit 不可用"; exit 1; }
echo "PASS"

# 测试 5: Element Web 健康检查
echo "[5/10] 检查 Element Web..."
curl -s http://localhost:10001 | grep -q "element" || { echo "FAIL: Element Web 不可用"; exit 1; }
echo "PASS"

# 测试 6: Agent 容器运行状态
echo "[6/10] 检查 Agent 容器..."
for agent in manager arch dev qa sre research; do
  docker compose ps | grep -q "clawteam-${agent}" || { echo "FAIL: ${agent} 容器未运行"; exit 1; }
done
echo "PASS"

# 测试 7-10: 预留扩展

echo ""
echo "=== 所有烟雾测试通过 ==="
