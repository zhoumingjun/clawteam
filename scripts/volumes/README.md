# 存储卷备份与恢复

本目录包含 Claw Team 存储卷的备份和恢复脚本。

## 文件说明

| 文件 | 说明 |
|------|------|
| `backup.sh` | 备份所有存储卷 |
| `restore.sh` | 从备份恢复存储卷 |

## 备份卷说明

Claw Team 使用三个主要存储卷：

| 卷名 | 用途 | Docker Compose 挂载点 |
|------|------|----------------------|
| `openclaw-config` | OpenClaw Agent 配置 | `/openclaw/config` |
| `openclaw-data` | OpenClaw 运行时数据 | `/openclaw/data` |
| `conduit-data` | Matrix 数据 | `/data` |

## 备份

```bash
# 创建备份（默认保存到 ./backups/）
bash scripts/volumes/backup.sh

# 指定备份目录
BACKUP_DIR=/path/to/backups bash scripts/volumes/backup.sh
```

备份将创建：
- `backups/clawteam_backup_{TIMESTAMP}.tar.gz` - 压缩备份包
- 包含所有三个存储卷的内容

## 恢复

```bash
# 恢复备份（会停止服务）
bash scripts/volumes/restore.sh backups/clawteam_backup_{TIMESTAMP}.tar.gz
```

**注意**: 恢复操作会停止服务并覆盖现有数据

## 查看备份列表

```bash
ls -la backups/
```

## 维护建议

1. **定期备份**: 建议每日或每次重要变更后执行备份
2. **离线备份**: 定期将 `./backups/` 目录备份到外部存储
3. **清理旧备份**: 定期清理过期的备份文件

```bash
# 清理 7 天前的备份
find backups/ -name "*.tar.gz" -mtime +7 -delete
```
