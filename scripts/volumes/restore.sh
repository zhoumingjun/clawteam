#!/bin/bash
# 恢复 Claw Team 存储卷

set -e

# 配置
BACKUP_DIR=${BACKUP_DIR:-./backups}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 用法说明
usage() {
    echo "用法: $0 <备份文件.tar.gz>"
    echo ""
    echo "示例:"
    echo "  $0 ./backups/clawteam_backup_20260330_120000.tar.gz"
    exit 1
}

# 检查参数
if [ -z "$1" ]; then
    log_error "请提供备份文件路径"
    usage
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    log_error "备份文件不存在: $BACKUP_FILE"
    exit 1
fi

log_info "=========================================="
log_info "Claw Team 恢复"
log_info "=========================================="
log_info "备份文件: ${BACKUP_FILE}"
log_info ""

# 确认操作
log_warn "此操作将覆盖现有数据。继续吗？"
read -p "输入 'yes' 继续: " confirm
if [ "$confirm" != "yes" ]; then
    log_info "取消恢复操作"
    exit 0
fi

# 创建临时目录
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

# 解压备份
log_info "解压备份文件..."
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# 找到备份内容目录
BACKUP_CONTENTS=$(ls "${TEMP_DIR}" | head -1)
BACKUP_PATH="${TEMP_DIR}/${BACKUP_CONTENTS}"

if [ ! -d "$BACKUP_PATH" ]; then
    log_error "无效的备份文件格式"
    exit 1
fi

# 停止服务
log_info "停止服务..."
docker compose down || true

# 清理现有数据
log_info "清理现有数据..."
rm -rf volumes/openclaw-config/* volumes/openclaw-data/* volumes/conduit-data/*

# 恢复数据
log_info "恢复 openclaw-config..."
if [ -d "${BACKUP_PATH}/openclaw-config" ]; then
    cp -r "${BACKUP_PATH}/openclaw-config/"* volumes/openclaw-config/
    log_info "  ✓ openclaw-config 已恢复"
else
    log_warn "openclaw-config 不在备份中"
fi

log_info "恢复 openclaw-data..."
if [ -d "${BACKUP_PATH}/openclaw-data" ]; then
    cp -r "${BACKUP_PATH}/openclaw-data/"* volumes/openclaw-data/
    log_info "  ✓ openclaw-data 已恢复"
else
    log_warn "openclaw-data 不在备份中"
fi

log_info "恢复 conduit-data..."
if [ -d "${BACKUP_PATH}/conduit-data" ]; then
    cp -r "${BACKUP_PATH}/conduit-data/"* volumes/conduit-data/
    log_info "  ✓ conduit-data 已恢复"
else
    log_warn "conduit-data 不在备份中"
fi

# 重启服务
log_info "重启服务..."
docker compose up -d

log_info ""
log_info "=========================================="
log_info "恢复完成!"
log_info "=========================================="
log_info ""
log_info "服务已重启，使用 'make logs' 查看状态"
log_info ""
