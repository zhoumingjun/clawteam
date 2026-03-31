# Claw Team 部署指南

本文档提供 Claw Team 的完整部署流程，涵盖开发环境搭建到生产环境加固。

**当前 MVP**：Matrix 使用 **[Tuwunel](https://github.com/matrix-construct/tuwunel)**（`containers/docker-compose.yml`，镜像 `ghcr.io/matrix-construct/tuwunel:v1.5.1`），OpenClaw 单容器。Synapse 数据**不可**原地迁移至 Tuwunel；切换请 **`make fresh`**。文中若仍有旧 Conduit / Synapse 表述，以本段为准。

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

### 2.4 Matrix 用户与团队房

在 `.env` 中设置 **`HUMAN_PASSWORD`** 与各 **`*_PASSWORD`** 后，执行 **`make fresh`** 或 **`make deploy`**：`devops/deploy.sh` 在 Tuwunel 就绪后用 Client API（`registration_token` = `MATRIX_REGISTRATION_TOKEN`）创建/登录用户，OpenClaw 启动脚本刷新 token、拉 Gateway、建/绑团队房。**已存在用户时无法在脚本中强制改密**（与旧 Synapse `register_new_matrix_user` 不同），改密请 `make fresh` 或在客户端操作。

### 2.5 验证部署

```bash
# 运行烟雾测试
make test-smoke

# 访问服务（Homeserver；Matrix 客户端自备）
echo "Tuwunel (Matrix): http://localhost:8008"
```

推荐首次部署直接运行项目根目录 **`./devops/deploy.sh`**（将创建 `volumes/`、拉起 `containers/docker-compose.yml` 定义的服务）。

### 2.6 Tuwunel 调优（限速、内存）

Tuwunel 通过 **`TUWUNEL_*` 环境变量** 或挂载 `tuwunel.toml` 配置（见 [tuwunel.chat/configuration](https://tuwunel.chat/configuration.html)）。Rust 版 homeserver 默认通常比 Synapse 更耐本地多客户端并发；若仍遇 `M_LIMIT_EXCEEDED`，请查官方文档中的频率与超时相关项，并在 **`containers/docker-compose.yml`** 的 `tuwunel.environment` 中追加变量后 `docker compose up -d tuwunel`。

## 3. 配置说明

### 3.1 .env 文件配置

以仓库根目录 **`.env.example`** 为权威模板（**`MATRIX_SERVER_NAME`**、**`MATRIX_PORT`**、**`ANTHROPIC_API_KEY`** / **`MODEL_NAME`**、**`HUMAN_PASSWORD`**、各 agent 密码等）。当前栈为 **Tuwunel + OpenClaw**，无 Conduit 变量。

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
lsof -i ":${MATRIX_PORT:-8008}"
lsof -i :8008

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

### 4.2 Tuwunel 无法就绪 / OpenClaw 连不上 Matrix

**症状**: `clawteam-tuwunel` 未启动或 `/_matrix/client/versions` 无响应，或 OpenClaw 日志报 Matrix 连接失败。

**排查**:
```bash
docker compose -f containers/docker-compose.yml --env-file .env ps
docker compose -f containers/docker-compose.yml --env-file .env logs tuwunel
curl -sf "http://127.0.0.1:${MATRIX_PORT:-8008}/_matrix/client/versions"
docker compose -f containers/docker-compose.yml --env-file .env exec openclaw \
  curl -sf "http://tuwunel:8008/_matrix/client/versions"
```

**常见处理**: 确认 `TUWUNEL_REGISTRATION_TOKEN` 与 `.env` 中 `MATRIX_REGISTRATION_TOKEN` 一致；账号问题执行 `make fresh` 重建环境；顽固状态同样可 `make fresh`。

### 4.3 Matrix 客户端无法连接 Homeserver

本仓库**不再**打包 Element Web。请使用自备客户端（如 Element），Homeserver URL 填 `http://localhost:8008`（与 `MATRIX_SERVER_NAME`、TLS 设置一致）。

**排查步骤**:
```bash
# 1. Tuwunel 是否响应
curl -sf "http://localhost:8008/_matrix/client/versions"

# 2. 容器与编排（compose 在 containers/）
docker compose -f containers/docker-compose.yml --env-file .env ps
docker compose -f containers/docker-compose.yml --env-file .env logs tuwunel
```

## 5. 生产环境加固

### 5.1 安全加固

#### 5.1.1 网络隔离

```yaml
# 与 containers/docker-compose.yml 一致：Tuwunel 仅绑定回环
services:
  tuwunel:
    ports:
      - "127.0.0.1:8008:8008"
```

#### 5.1.2 注册策略

生产环境请关闭公开注册，使用强 **`MATRIX_REGISTRATION_TOKEN`**，并按 [Tuwunel 文档](https://tuwunel.chat/configuration.html) 加固；勿依赖历史上的 Conduit 环境变量。

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
        proxy_pass http://127.0.0.1:8008;  # Tuwunel Client-Server API
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
# ufw deny 8008/tcp   # 若 Tuwunel 仅应经反向代理暴露，可按需限制直连端口
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
# 与 containers/docker-compose.yml 中 tuwunel 服务类似
services:
  tuwunel:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8008/_matrix/client/versions"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### 5.4 备份策略

#### 5.4.1 自动化备份

```bash
# crontab -e
# 每日凌晨 2:00 执行备份
0 2 * * * cd /path/to/clawteam && bash platform/volumes/backup.sh >> logs/backup.log 2>&1

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
bash platform/volumes/restore.sh /path/to/backups/clawteam_backup_YYYYMMDD_HHMMSS.tar.gz

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

# 更新服务（编排文件在 containers/）
git pull
docker compose -f containers/docker-compose.yml --env-file .env pull
docker compose -f containers/docker-compose.yml --env-file .env up -d
```

### 6.2 版本升级

```bash
# 1. 备份当前环境
bash platform/volumes/backup.sh

# 2. 拉取新版本
git pull

# 3. 更新配置（如有变更）
vim .env

# 4. 重启服务
docker compose -f containers/docker-compose.yml --env-file .env down
docker compose -f containers/docker-compose.yml --env-file .env up -d

# 5. 验证
make test-smoke
```

## 7. 参考链接

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 官方文档](https://docs.docker.com/compose/)
- [Tuwunel](https://tuwunel.chat/)
- [Matrix 客户端 Element](https://element.io/)（自备，连接本机 Tuwunel）
- [12-Factor App](https://12factor.net/)
