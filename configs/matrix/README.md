# Matrix (Conduit) 配置

本目录包含 Conduit Matrix Homeserver 的配置和初始化脚本。

## 文件说明

| 文件 | 说明 |
|------|------|
| `conduit.yaml` | Conduit 服务配置文件 |
| `init.sh` | 用户和房间初始化脚本 |

## 配置

### conduit.yaml

主要配置项：

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `server_name` | 服务器名称（域名） | `localhost:10000` |
| `database_path` | 数据库文件路径 | `/data/conduit.db` |
| `port` | 服务端口 | `6167` |
| `allow_registration` | 允许新用户注册 | `true` |
| `registration_shared_secret` | 注册共享密钥（Admin API） | `clawteam-secret-change-me` |
| `log` | 日志级别 | `info` |
| `max_request_size` | 最大请求大小（字节） | `20000000` |

## 使用方法

### 1. 启动 Conduit 服务

```bash
make up
```

### 2. 初始化用户和房间

```bash
# 确保 Conduit 已启动
make ps

# 运行初始化脚本
bash configs/matrix/init.sh
```

### 3. 通过 Element Web 登录

访问 http://localhost:10001

使用以下账号登录：

| 用户 | 用户名 | 密码 |
|------|--------|------|
| Human | `@human` | `human_password` |
| Manager | `@manager` | `manager_password` |
| Arch | `@arch` | `arch_password` |
| Dev | `@dev` | `dev_password` |
| QA | `@qa` | `qa_password` |
| SRE | `@sre` | `sre_password` |
| Research | `@research` | `research_password` |

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `CONDUIT_SERVER` | Conduit 服务器地址 | `http://localhost:10000` |
| `CONDUIT_ADMIN_SECRET` | Admin API 密钥 | `clawteam-secret-change-me` |

## 故障排查

### Conduit 无法启动

检查端口是否被占用：
```bash
lsof -i :10000
```

### 无法创建用户

确认 `registration_shared_secret` 与 `conduit.yaml` 中配置一致。

### 房间创建失败

某些房间 ID 可能已存在，脚本会自动跳过。
