#!/bin/bash
# 备份 Claw Team 所有存储卷

set -e

# 配置
BACKUP_DIR=${BACKUP_DIR:-./backups}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="clawteam_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

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

# 创建备份目录
mkdir -p "${BACKUP_PATH}"

log_info "=========================================="
log_info "Claw Team 备份"
log_info "=========================================="
log_info "备份路径: ${BACKUP_PATH}"
log_info ""

# 备份 openclaw-config
if [ -d "volumes/openclaw-config" ] && [ "$(ls -A volumes/openclaw-config 2>/dev/null)" ]; then
    log_info "备份 openclaw-config..."
    cp -r volumes/openclaw-config "${BACKUP_PATH}/"
    log_info "  ✓ openclaw-config 已备份"
else
    log_warn "openclaw-config 为空或不存在，跳过"
fi

# 备份 openclaw-data
if [ -d "volumes/openclaw-data" ] && [ "$(ls -A volumes/openclaw-data 2>/dev/null)" ]; then
    log_info "备份 openclaw-data..."
    cp -r volumes/openclaw-data "${BACKUP_PATH}/"
    log_info "  ✓ openclaw-data 已备份"
else
    log_warn "openclaw-data 为空或不存在，跳过"
fi

# 备份 conduit-data
if [ -d "volumes/conduit-data" ] && [ "$(ls -A volumes/conduit-data 2>/dev/null)" ]; then
    log_info "备份 conduit-data..."
    cp -r volumes/conduit-data "${BACKUP_PATH}/"
    log_info "  ✓ conduit-data 已备份"
else
    log_warn "conduit-data 为空或不存在，跳过"
fi

# 创建备份清单
cat > "${BACKUP_PATH}/manifest.txt" << EOF
Claw Team Backup Manifest
=========================
Backup Date: $(date)
Hostname: $(hostname)
Backup Path: ${BACKUP_PATH}

Contents:
$(ls -la "${BACKUP_PATH}")

EOF

# 创建压缩包
log_info "创建压缩包..."
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
rm -rf "${BACKUP_NAME}"

log_info ""
log_info "=========================================="
log_info "备份完成!"
log_info "=========================================="
log_info ""
log_info "备份文件: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
log_info ""
log_info "恢复命令:"
log_info "  bash volumes/restore.sh ${BACKUP_NAME}.tar.gz"
log_info ""
