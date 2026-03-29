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
| `allow_registration` | 允许新用户注册 | `false` |
| `allow_password_login` | 允许密码登录 | `true` |
| `allow_federation` | 允许跨服务器通信 | `false` |

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `CONDUIT_SERVER` | Conduit 服务器地址 | `http://localhost:10000` |
| `CONDUIT_PORT` | 主机映射端口 | `10000` |
| `CONDUIT_ALLOW_REGISTRATION` | 允许新用户注册 | `false` |
| `ELEMENT_PORT` | Element Web 端口 | `10001` |

## 用户密码

**重要**: 所有用户密码通过环境变量设置，不在代码中存储。

初始化前设置环境变量：

```bash
export MANAGER_PASSWORD="your-secure-manager-password"
export HUMAN_PASSWORD="your-secure-human-password"
export ARCH_PASSWORD="your-arch-password"
export DEV_PASSWORD="your-dev-password"
export QA_PASSWORD="your-qa-password"
export SRE_PASSWORD="your-sre-password"
export RESEARCH_PASSWORD="your-research-password"
```

然后运行初始化脚本：
```bash
bash configs/matrix/init.sh
```

## 使用方法

### 1. 启动 Conduit 服务

```bash
make up
```

### 2. 初始化用户

```bash
# 设置密码并运行初始化
export MANAGER_PASSWORD="your-secure-password"
export HUMAN_PASSWORD="your-secure-password"
# ... 设置其他密码
bash configs/matrix/init.sh
```

### 3. 通过 Element Web 登录

访问 http://localhost:10001

使用环境变量中设置的密码登录。

## 安全加固（生产环境）

1. **禁用用户注册**
   ```bash
   export CONDUIT_ALLOW_REGISTRATION=false
   ```

2. **限制端口访问**
   - 开发环境：暴露在所有接口
   - 生产环境：使用反向代理 + TLS，仅允许特定网络访问

3. **启用联邦（谨慎）**
   ```yaml
   allow_federation: true
   ```

## 故障排查

### Conduit 无法启动

检查端口是否被占用：
```bash
lsof -i :10000
```

### 用户创建失败

确认环境变量已正确设置，且 `CONDUIT_ALLOW_REGISTRATION=true`。

### 房间创建失败

脚本会自动跳过已存在的房间，这是预期行为。
