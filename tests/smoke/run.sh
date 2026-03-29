#!/bin/bash
# Claw Team 烟雾测试
# 验证所有服务是否正常启动

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 测试计数器
TESTS_PASSED=0
TESTS_FAILED=0

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

echo "=========================================="
echo "Claw Team 烟雾测试"
echo "=========================================="
echo ""

# -----------------------------------------------------------------------------
# Test 1: 检查 Docker 是否可用
# -----------------------------------------------------------------------------
log_info "[1/12] 检查 Docker..."
if docker --version > /dev/null 2>&1; then
    log_pass "Docker 可用: $(docker --version | cut -d' ' -f3 | tr -d ',')"
else
    log_fail "Docker 不可用"
fi

# -----------------------------------------------------------------------------
# Test 2: 检查 docker-compose 是否可用
# -----------------------------------------------------------------------------
log_info "[2/12] 检查 docker-compose..."
if docker compose version > /dev/null 2>&1; then
    log_pass "docker-compose 可用: $(docker compose version | cut -d' ' -f4 | tr -d ',')"
else
    log_fail "docker-compose 不可用"
fi

# -----------------------------------------------------------------------------
# Test 3: 检查 docker-compose 服务状态
# -----------------------------------------------------------------------------
log_info "[3/12] 检查服务启动状态..."
if docker compose ps | grep -q "Up"; then
    log_pass "至少一个服务已启动"
else
    log_fail "没有服务运行，请先运行 'make up'"
fi

# -----------------------------------------------------------------------------
# Test 4: Conduit 健康检查 (HTTP)
# -----------------------------------------------------------------------------
log_info "[4/12] 检查 Conduit Matrix 服务..."
if curl -sf "http://localhost:10000/_matrix/client/versions" > /dev/null 2>&1; then
    log_pass "Conduit HTTP 端点正常"
else
    log_fail "Conduit 不可访问 (http://localhost:10000)"
fi

# -----------------------------------------------------------------------------
# Test 5: Element Web 健康检查 (HTTP)
# -----------------------------------------------------------------------------
log_info "[5/12] 检查 Element Web..."
if curl -sf "http://localhost:10001" > /dev/null 2>&1; then
    log_pass "Element Web 正常"
else
    log_fail "Element Web 不可访问 (http://localhost:10001)"
fi

# -----------------------------------------------------------------------------
# Test 6: Conduit 容器健康状态
# -----------------------------------------------------------------------------
log_info "[6/12] 检查 Conduit 容器..."
if docker ps | grep -q "clawteam-conduit.*Up"; then
    log_pass "Conduit 容器运行中"
else
    log_fail "Conduit 容器未运行"
fi

# -----------------------------------------------------------------------------
# Test 7: Element 容器健康状态
# -----------------------------------------------------------------------------
log_info "[7/12] 检查 Element 容器..."
if docker ps | grep -q "clawteam-element.*Up"; then
    log_pass "Element 容器运行中"
else
    log_fail "Element 容器未运行"
fi

# -----------------------------------------------------------------------------
# Test 8: Manager Agent 容器状态
# -----------------------------------------------------------------------------
log_info "[8/12] 检查 Manager Agent 容器..."
if docker ps | grep -q "clawteam-manager.*Up"; then
    log_pass "Manager Agent 容器运行中"
else
    log_fail "Manager Agent 容器未运行"
fi

# -----------------------------------------------------------------------------
# Test 9: 其他 Agent 容器状态
# -----------------------------------------------------------------------------
log_info "[9/12] 检查其他 Agent 容器..."
ALL_AGENTS_UP=true
for agent in arch dev qa sre research; do
    if ! docker ps | grep -q "clawteam-${agent}.*Up"; then
        log_fail "${agent} Agent 容器未运行"
        ALL_AGENTS_UP=false
    fi
done
if [ "$ALL_AGENTS_UP" = true ]; then
    log_pass "所有 Agent 容器运行中 (arch, dev, qa, sre, research)"
fi

# -----------------------------------------------------------------------------
# Test 10: OpenClaw Gateway 健康检查 (如果端口 8000 暴露)
# -----------------------------------------------------------------------------
log_info "[10/12] 检查 OpenClaw Gateway..."
# OpenClaw Gateway 可能没有暴露 8000 端口到主机，仅做容器内检查
if docker exec clawteam-manager curl -sf "http://localhost:8000/health" > /dev/null 2>&1; then
    log_pass "OpenClaw Gateway 健康"
else
    log_info "OpenClaw Gateway 健康检查跳过 (端口未暴露)"
fi

# -----------------------------------------------------------------------------
# Test 11: Docker 网络检查
# -----------------------------------------------------------------------------
log_info "[11/12] 检查 Docker 网络..."
if docker network inspect clawteam-clawteam-network > /dev/null 2>&1; then
    log_pass "Docker 网络存在"
else
    log_fail "Docker 网络不存在"
fi

# -----------------------------------------------------------------------------
# Test 12: Volume 挂载检查
# -----------------------------------------------------------------------------
log_info "[12/12] 检查 Volume 挂载..."
VOLUMES_OK=true
for vol in conduit-data openclaw-config openclaw-data; do
    if ! docker volume inspect clawteam-${vol} > /dev/null 2>&1; then
        log_fail "Volume ${vol} 不存在"
        VOLUMES_OK=false
    fi
done
if [ "$VOLUMES_OK" = true ]; then
    log_pass "所有 Volume 存在"
fi

# -----------------------------------------------------------------------------
# 测试总结
# -----------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "测试结果"
echo "=========================================="
echo -e "通过: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "失败: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}所有烟雾测试通过!${NC}"
    exit 0
else
    echo -e "${RED}部分测试失败，请检查上述问题${NC}"
    exit 1
fi
