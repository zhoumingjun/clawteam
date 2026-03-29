# Claw Team 最佳实践

本文档记录项目遵循的行业最佳实践标准。

## Docker Compose 最佳实践

### 镜像标签
- ❌ 不要使用 `latest` tag
- ✅ 使用固定版本标签（如 `nginx:1.25.4`）

### Healthcheck
- ✅ 必须配置 `healthcheck`
- ✅ 使用 `depends_on` + `condition: service_healthy`

### 重启策略
- ✅ 明确使用 `always` 或 `unless-stopped`
- ❌ 避免 `on-failure` 无限制重试

### 网络
- ✅ 使用命名网络而非默认网络
- ✅ 合理规划端口映射

### 示例

```yaml
services:
  web:
    image: nginx:1.25.4
    restart: unless-stopped
    ports:
      - "8080:80"
    networks:
      - app-network
    depends_on:
      api:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

networks:
  app-network:
    driver: bridge
```

## Matrix Homeserver 选型

### Conduit vs Synapse

| 特性 | Conduit | Synapse |
|------|----------|---------|
| 成熟度 | 中等 | 高 |
| 资源占用 | 低 | 中 |
| Admin API | 有限 | 完整 |
| 稳定性 | 良好 | 优秀 |

### 建议
- 开发/小规模部署：Conduit（轻量）
- 生产/大规模部署：Synapse（完整功能）

## Shell 脚本最佳实践

### 必须项
- ✅ `set -euo pipefail`（严格模式）
- ✅ 变量引用加引号 `"$var"`
- ✅ 使用 `shellcheck` 进行 lint 检查

### 变量规范
```bash
# ✅ 正确
local name="value"
if [ "$name" = "test" ]; then
    echo "Hello ${name}"
fi

# ❌ 错误
set -e
name=value  # 危险！
if [ $name = test ]; then
    echo "Hello $name"
fi
```

## 12-Factor App（云原生应用原则）

| 原则 | 说明 |
|------|------|
| 1. Codebase | 一份代码，多个部署 |
| 2. Dependencies | 显式声明依赖 |
| 3. Config | 配置在环境变量 |
| 4. Backing services | 后端服务当作资源 |
| 5. Build, release, run | 严格分离构建和运行 |
| 6. Processes | 无状态 |
| 7. Port binding | 通过端口绑定暴露服务 |
| 8. Concurrency | 进程模型扩展 |
| 9. Disposability | 快速启动和优雅停止 |
| 10. Dev/prod parity | 开发与生产环境一致 |
| 11. Logs | 把日志当作事件流 |
| 12. Admin processes | 管理任务当作一次性进程 |

## 安全加固

### CIS Docker Benchmark
- 容器以非 root 用户运行
- 限制容器 Capabilities
- 禁用 privileged 模式
- 资源限制（CPU、内存）

### OWASP Top 10（Web 组件）
- A01: Broken Access Control
- A02: Cryptographic Failures
- A03: Injection
- A04: Insecure Design
- A05: Security Misconfiguration
- A06: Vulnerable Components
- A07: Authentication Failures
- A08: Software and Data Integrity
- A09: Logging Failures
- A10: SSRF

## 备份恢复（3-2-1 原则）

### 3-2-1 原则
- **3 份数据副本**：主数据 + 2 份备份
- **2 种不同介质**：如磁盘 + 云存储
- **1 份异地备份**：不在同一地理位置

### 备份类型
| 类型 | 频率 | RPO |
|------|------|-----|
| 全量备份 | 每日 | 24h |
| 增量备份 | 每小时 | 1h |
| 实时复制 | 持续 | < 5min |

### 恢复验证
- ✅ 定期演练备份恢复流程
- ✅ 验证恢复时间（RTO）
- ✅ 验证数据完整性（RPO）

## 参考链接

- [Docker Compose 官方文档](https://docs.docker.com/compose/compose-file/)
- [ShellCheck](https://www.shellcheck.net/)
- [12-Factor App](https://12factor.net/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Top 10](https://owasp.org/Top10/)
