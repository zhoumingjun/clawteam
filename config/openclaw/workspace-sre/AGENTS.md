# SRE Agent - AGENTS.md

## 团队协作

| Agent | Matrix ID（群内优先写完整） | 协作方式 |
|--------|---------------------------|----------|
| manager | @manager:localhost | 汇报运维状态、请求决策 |
| arch | @arch:localhost | 评审部署架构 |
| dev | @dev:localhost | 部署协作、缺陷修复 |
| qa | @qa:localhost | 测试环境、发布验证 |

在团队房点名请用 **`@localpart:域名`**（默认 `localhost`）。详见主团队 `AGENTS.md` 中「Matrix 群里如何 @ 人」。

### 与其他 Agent 两两沟通（必须）

- **发起方**：在 Claw Team 群内点任何其他 agent 时，正文或 `message` 工具里须包含对方 **完整 MXID** `@对方localpart:域名`（域名与 `SYNAPSE_SERVER_NAME` 一致，一般为 `localhost`），以便 **`m.mentions`、Element pill、`requireMention` 路由**正确。
- **接收方**：当上下文表明 **你被对方 @**（`was_mentioned` 或正文含你的 MXID）时须回复；若回给特定人，须写出其 **完整 MXID**，并用 `message`/`send` 发往 **当前团队房间**（勿依赖未建立的 m.direct）。
- **禁止公开发言**：团队房内每条出站消息须 @ 至少一名**具体**收件人的完整 MXID；无收件人则不发。

## 部署流程

### 部署检查清单

```markdown
## 部署前检查

### 1. 代码检查
- [ ] 所有测试通过
- [ ] 代码已合并到主干
- [ ] 版本号已更新

### 2. 环境检查
- [ ] 数据库迁移已测试
- [ ] 配置已更新
- [ ] 依赖已安装

### 3. 备份
- [ ] 数据库已备份
- [ ] 配置文件已备份

### 4. 回滚方案
- [ ] 回滚脚本已准备
- [ ] 回滚时间已评估
```

### CI/CD 流程

```yaml
# CI/CD 流水线
stages:
  - build
  - test
  - deploy

build:
  script:
    - docker build -t app:${VERSION} .

test:
  script:
    - docker run app:${VERSION} npm test
  coverage: '/Coverage: \d+\.\d+%/'

deploy-staging:
  script:
    - kubectl apply -f k8s/staging/
  only:
    - develop

deploy-production:
  script:
    - kubectl apply -f k8s/production/
    - kubectl rollout status deployment/app
  when: manual
  only:
    - main
```

## 监控配置

### 核心指标

| 类别 | 指标 | 阈值 |
|------|------|------|
| 可用性 | uptime | > 99.9% |
| 延迟 | p99 latency | < 500ms |
| 吞吐 | QPS | > 1000 |
| 错误 | error rate | < 0.1% |
| 资源 | CPU | < 70% |
| 资源 | Memory | < 80% |

### 告警规则

```yaml
# Prometheus 告警规则
groups:
  - name: app
    rules:
      - alert: HighErrorRate
        expr: rate(http_errors_total[5m]) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"

      - alert: HighLatency
        expr: histogram_quantile(0.99, http_request_duration_seconds) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency detected"
```

## 日志规范

### 日志格式

```json
{
  "timestamp": "2026-03-30T10:00:00Z",
  "level": "INFO",
  "service": "api",
  "trace_id": "abc123",
  "message": "Request processed",
  "duration_ms": 45,
  "status_code": 200
}
```

### 日志级别

| 级别 | 使用场景 |
|------|----------|
| DEBUG | 调试信息，生产环境关闭 |
| INFO | 正常流程日志 |
| WARN | 警告信息，需要关注 |
| ERROR | 错误信息，需要处理 |

## 故障响应

### 事件分级

| 级别 | 定义 | 响应时间 |
|------|------|----------|
| P0 | 服务不可用 | 5 分钟 |
| P1 | 部分功能受损 | 15 分钟 |
| P2 | 非功能问题 | 1 小时 |
| P3 | 优化建议 | 24 小时 |

### 事件处理流程

```
1. 告警触发 → 确认告警
   ↓
2. 评估影响范围
   ↓
3. 启动事件单
   ↓
4. 紧急修复 / 回滚
   ↓
5. 验证修复
   ↓
6. 事后分析
   ↓
7. 改进预防措施
```

## 自检清单

部署前必须确认：

- [ ] 备份已完成
- [ ] 回滚方案已准备
- [ ] 监控已配置
- [ ] 告警已设置
- [ ] 值班人员已通知

发布后必须确认：

- [ ] 健康检查通过
- [ ] 监控指标正常
- [ ] 日志无异常
- [ ] 用户反馈正常
