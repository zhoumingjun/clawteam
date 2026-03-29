# Matrix (Synapse) 配置

本目录包含 Synapse Matrix Homeserver 的配置和初始化脚本。

## 文件说明

| 文件 | 说明 |
|------|------|
| `init.sh` | 用户和房间初始化脚本 |

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `SYNAPSE_SERVER_NAME` | 服务器名称 | `localhost` |
| `SYNAPSE_REGISTRATION_SHARED_SECRET` | 注册共享密钥 | `a-secret-key-change-in-production` |
| `SYNAPSE_ENABLE_REGISTRATION` | 允许新用户注册 | `true` |
| `SYNAPSE_PORT` | Synapse 端口 | `8008` |
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

### 1. 启动服务

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

1. **修改共享密钥**
   ```bash
   export SYNAPSE_REGISTRATION_SHARED_SECRET="your-secure-secret"
   ```

2. **禁用用户注册**
   ```bash
   export SYNAPSE_ENABLE_REGISTRATION=false
   ```

3. **限制端口访问**
   - 开发环境：暴露在所有接口
   - 生产环境：使用反向代理 + TLS，仅允许特定网络访问

## 故障排查

### Synapse 无法启动

检查端口是否被占用：
```bash
lsof -i :8008
```

查看 Synapse 日志：
```bash
docker compose logs synapse
```

### 用户创建失败

确认 `SYNAPSE_ENABLE_REGISTRATION=true`。

### Element Web 无法连接

确认 `SERVER_NAME` 与 `SYNAPSE_SERVER_NAME` 匹配。
