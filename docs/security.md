# Claw Team 安全加固

## 端口安全

### 当前配置（MVP）

| 服务 | 端口 | 绑定地址 | 说明 |
|------|------|----------|------|
| Synapse | 8008 | 127.0.0.1 | Matrix Client-Server API（自备 Matrix 客户端连接此端口） |

**当前策略**: 仅允许本地访问（localhost/127.0.0.1）

### 端口绑定说明

```yaml
# 本地开发（当前）
ports:
  - "127.0.0.1:8008:8008"  # 只允许本机访问

# 内网访问（需要代理）
ports:
  - "10.0.0.1:8008:8008"    # 特定内网 IP

# 公网访问（生产 - 需要 TLS）
# 不推荐直接暴露，使用反向代理
```

## 生产环境部署

### 1. 反向代理 + TLS

```nginx
# /etc/nginx/conf.d/clawteam.conf
server {
    listen 443 ssl;
    server_name matrix.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # Matrix Synapse
    location / {
        proxy_pass http://127.0.0.1:8008;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

```

### 2. 防火墙规则（Linux）

```bash
# 允许 SSH (22)
ufw allow 22/tcp

# 允许 HTTPS (443) - 通过反向代理访问
ufw allow 443/tcp

# 禁止直接访问 Synapse 端口（仅经反向代理暴露 443）
ufw deny 8008/tcp

# 启用防火墙
ufw enable
```

### 3. Docker 网络隔离

```yaml
# 生产环境使用自定义网络
services:
  tuwunel:
    networks:
      - internal-network

  # 不暴露任何端口，使用反向代理
  # nginx 通过 internal-network 访问

networks:
  internal-network:
    driver: bridge
```

## 安全检查清单

### 开发环境
- [ ] Tuwunel 只绑定 127.0.0.1
- [ ] API Key 不写入代码
- [ ] 使用强密码

### 生产环境
- [ ] 使用 TLS/SSL 证书
- [ ] 反向代理配置正确
- [ ] 防火墙规则生效
- [ ] 禁用 Synapse 外部注册
- [ ] API Key 通过环境变量或密钥管理服务注入
- [ ] 定期备份数据

## 相关文档

- `deploy/homeserver.yaml` - Synapse 配置（构建进镜像）
- `docs/deployment-guide.md` - 部署指南
