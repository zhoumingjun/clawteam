# Claw Team 部署指南

本文档提供 Claw Team 的完整部署流程，涵盖开发环境搭建到生产环境加固。

## 1. 环境要求

### 1.1 系统要求

| 组件 | 最低要求 | 推荐配置 |
|------|----------|----------|
| CPU | 4 cores | 8+ cores |
| 内存 | 8 GB | 16+ GB |
| 磁盘 | 20 GB | 50+ GB SSD |
| 系统 | macOS 12+ / Ubuntu 20.04+ / Debian 11+ | |

### 1.2 软件要求

| 软件 | 最低版本 | 推荐版本 |
|------|----------|----------|
| Docker | 20.10+ | 24.0+ |
| Docker Compose | 2.0+ | 2.20+ |
| Git | 2.30+ | 最新稳定版 |
| Make | 3.81+ | 最新稳定版 |

### 1.3 验证安装

```bash
# 验证 Docker
docker --version
# Docker version 24.0.0+

# 验证 Docker Compose
docker compose version
# Docker Compose version v2.20.0

# 验证 Make
make --version
# GNU Make 4.3+
```

## 2. 安装步骤

### 2.1 克隆代码

```bash
git clone https://github.com/zhoumingjun/clawteam.git
cd clawteam
```

### 2.2 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件（见 3. 配置说明）
vim .env
```

### 2.3 启动服务

```bash
# 构建并启动所有服务
make up

# 查看服务状态
make ps

# 查看日志
make logs
```

### 2.4 初始化 Matrix 用户

```bash
# 设置用户密码（必须设置强密码）
export MANAGER_PASSWORD="your-secure-manager-password"
export HUMAN_PASSWORD="your-secure-human-password"
export ARCH_PASSWORD="your-secure-arch-password"
export DEV_PASSWORD="your-secure-dev-password"
export QA_PASSWORD="your-secure-qa-password"
export SRE_PASSWORD="your-secure-sre-password"
export RESEARCH_PASSWORD="your-secure-research-password"

# 允许用户注册（仅初始化时）
export CONDUIT_ALLOW_REGISTRATION=true

# 运行初始化脚本
bash configs/matrix/init.sh
```

### 2.5 验证部署

```bash
# 运行烟雾测试
make test-smoke

# 访问服务
echo "Conduit (Matrix): http://localhost:10000"
echo "Element Web: http://localhost:10001"
```

## 3. 配置说明

### 3.1 .env 文件配置

```bash
# ============================================
# Matrix / Conduit 配置
# ============================================

# Conduit 服务器名称（必须与域名匹配）
CONDUIT_SERVER=localhost:10000

# 是否允许新用户注册（生产环境设为 false）
CONDUIT_ALLOW_REGISTRATION=false

# ============================================
# Agent API Keys
# ============================================
# 每个 Agent 都需要独立的 Claude API Key

MANAGER_API_KEY=sk-ant-your-manager-key
ARCH_API_KEY=sk-ant-your-arch-key
DEV_API_KEY=sk-ant-your-dev-key
QA_API_KEY=sk-ant-your-qa-key
SRE_API_KEY=sk-ant-your-sre-key
RESEARCH_API_KEY=sk-ant-your-research-key

# ============================================
# Agent 模型配置（可选）
# ============================================
# 默认使用 claude-opus-4-20250514

# MANAGER_MODEL=claude-opus-4-20250514
# ARCH_MODEL=claude-opus-4-20250514
# DEV_MODEL=claude-sonnet-4-20250514
# QA_MODEL=claude-sonnet-4-20250514
# SRE_MODEL=claude-haiku-4-20250514
# RESEARCH_MODEL=claude-opus-4-20250514

# ============================================
# 用户密码
# ============================================
# 初始化后建议删除这些变量

MANAGER_PASSWORD=your-secure-manager-password
HUMAN_PASSWORD=your-secure-human-password
ARCH_PASSWORD=your-secure-arch-password
DEV_PASSWORD=your-secure-dev-password
QA_PASSWORD=your-secure-qa-password
SRE_PASSWORD=your-secure-sre-password
RESEARCH_PASSWORD=your-secure-research-password

# ============================================
# 网络端口
# ============================================

# Conduit Matrix 端口
CONDUIT_PORT=10000

# Element Web 端口
ELEMENT_PORT=10001
```

### 3.2 敏感信息管理

| 信息类型 | 处理方式 |
|----------|----------|
| API Keys | 必须通过 .env 注入，不写入代码 |
| 用户密码 | 初始化后立即删除或更改 |
| 数据库凭证 | 使用强密码，通过环境变量注入 |

## 4. 故障排查

### 4.1 服务无法启动

**症状**: `make up` 报错误

**排查步骤**:
```bash
# 1. 检查 Docker 是否运行
docker ps

# 2. 检查端口占用
lsof -i :10000
lsof -i :10001

# 3. 查看详细日志
docker compose up -d
docker compose logs
```

**常见解决方案**:

| 问题 | 解决方案 |
|------|----------|
| 端口占用 | 停止占用端口的服务或修改 .env 中的端口 |
| 权限不足 | 将用户加入 docker 组: `sudo usermod -aG docker $USER` |
| 磁盘空间不足 | 清理 Docker: `docker system prune -a` |

### 4.2 Conduit 无法启动

**症状**: Conduit 容器状态为 `Restarting`

**排查步骤**:
```bash
# 查看 Conduit 日志
docker compose logs conduit

# 检查配置文件
cat configs/matrix/conduit.yaml
```

**解决方案**:
```bash
# 清理 Conduit 数据并重启
docker compose down
rm -rf volumes/conduit-data/*
docker compose up -d
bash configs/matrix/init.sh
```

### 4.3 Agent 无法连接 Matrix

**症状**: Agent 日志显示连接失败

**排查步骤**:
```bash
# 1. 检查 Conduit 是否健康
curl http://localhost:10000/_matrix/client/versions

# 2. 检查 Agent 日志
docker compose logs manager

# 3. 检查网络连接
docker compose exec manager curl -v http://conduit:6167/_matrix/client/versions
```

**解决方案**:
```bash
# 重启 Agent
docker compose restart manager arch dev qa sre research
```

### 4.4 初始化脚本失败

**症状**: `init.sh` 执行报错

**排查步骤**:
```bash
# 1. 确认环境变量已设置
echo $MANAGER_PASSWORD

# 2. 确认 CONDUIT_ALLOW_REGISTRATION=true
echo $CONDUIT_ALLOW_REGISTRATION

# 3. 手动测试 API
curl -X POST http://localhost:10000/_matrix/client/r0/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test","auth":{"type":"m.login.dummy"}}'
```

### 4.5 Element Web 无法访问

**症状**: 浏览器访问 `http://localhost:10001` 无响应

**排查步骤**:
```bash
# 1. 检查 Element 容器状态
docker compose ps element

# 2. 查看 Element 日志
docker compose logs element

# 3. 检查端口映射
docker port clawteam-element
```

**解决方案**:
```bash
# 重启 Element
docker compose restart element
```

## 5. 生产环境加固

### 5.1 安全加固

#### 5.1.1 网络隔离

```yaml
# docker-compose.yml
services:
  conduit:
    ports:
      - "127.0.0.1:10000:6167"  # 仅本地访问

  element:
    ports:
      - "127.0.0.1:10001:80"   # 仅本地访问
```

#### 5.1.2 禁用用户注册

```bash
# .env
CONDUIT_ALLOW_REGISTRATION=false
```

#### 5.1.3 API Key 安全

```bash
# 不要在 .env 中存储明文密码
# 使用密钥管理服务 (AWS Secrets Manager, HashiCorp Vault)

# 或使用 Docker secrets
echo "your-api-key" | docker secret create manager_api_key -
```

#### 5.1.4 容器安全

```yaml
# docker-compose.yml
services:
  manager:
    security_opt:
      - no-new-privileges:true
    read_only:true
    tmpfs:
      - /tmp
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
```

### 5.2 网络加固

#### 5.2.1 使用反向代理 + TLS

```nginx
# nginx.conf (生产环境)
server {
    listen 443 ssl;
    server_name matrix.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:10000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 5.2.2 防火墙规则

```bash
# 仅允许必要端口
# ufw allow 22/tcp    # SSH
# ufw allow 443/tcp   # HTTPS
# ufw deny 10000/tcp  # 禁止直接访问 Matrix
# ufw deny 10001/tcp  # 禁止直接访问 Element
```

### 5.3 监控配置

#### 5.3.1 日志收集

```yaml
# docker-compose.yml
services:
  manager:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # 使用 Loki/Prometheus 收集日志
  loki:
    image: grafana/loki:latest
```

#### 5.3.2 健康检查

```yaml
# 确保所有服务配置 healthcheck
services:
  conduit:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6167/_matrix/client/versions"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### 5.4 备份策略

#### 5.4.1 自动化备份

```bash
# crontab -e
# 每日凌晨 2:00 执行备份
0 2 * * * cd /path/to/clawteam && bash scripts/volumes/backup.sh >> logs/backup.log 2>&1

# 保留最近 30 天备份
0 3 * * * find /path/to/backups -name "*.tar.gz" -mtime +30 -delete
```

#### 5.4.2 异地备份

```bash
# 同步到远程存储
0 4 * * * rsync -avz /path/to/backups/ user@remote:/backup/clawteam/
```

### 5.5 灾难恢复

#### 5.5.1 恢复流程

```bash
# 1. 在新服务器部署
git clone https://github.com/zhoumingjun/clawteam.git
cd clawteam

# 2. 停止服务
make down

# 3. 恢复数据
bash scripts/volumes/restore.sh /path/to/backups/clawteam_backup_YYYYMMDD_HHMMSS.tar.gz

# 4. 重启服务
make up

# 5. 验证
make test-smoke
```

#### 5.5.2 RTO/RPO 目标

| 指标 | 目标 | 实现方式 |
|------|------|----------|
| RTO (恢复时间目标) | < 1 小时 | 标准化部署流程 |
| RPO (恢复点目标) | < 24 小时 | 每日备份 |

## 6. 维护

### 6.1 日常维护

```bash
# 查看服务状态
make ps

# 查看日志
make logs

# 清理未使用的 Docker 资源
docker system prune -f

# 更新服务
git pull
docker compose pull
docker compose up -d
```

### 6.2 版本升级

```bash
# 1. 备份当前环境
bash scripts/volumes/backup.sh

# 2. 拉取新版本
git pull

# 3. 更新配置（如有变更）
vim .env

# 4. 重启服务
docker compose down
docker compose up -d

# 5. 验证
make test-smoke
```

## 7. 参考链接

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 官方文档](https://docs.docker.com/compose/)
- [Conduit Matrix](https://gitlab.com/famedly/conduit)
- [Element Web](https://vector-im.github.io/element-web/)
- [12-Factor App](https://12factor.net/)
