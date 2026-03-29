# Manager Agent - HEARTBEAT.md

## 心跳检查配置

**检查频率**: 每 30 分钟
**触发时间**: 固定时间 + 随机偏移（避免多 Agent 同时检查）

## 检查项

### 1. 服务状态检查

检查所有 Agent 容器的健康状态：

```
检查列表:
- conduit (Matrix): docker ps | grep clawteam-conduit | grep -q Up
- element (Web): docker ps | grep clawteam-element | grep -q Up
- manager: docker ps | grep clawteam-manager | grep -q Up
- arch: docker ps | grep clawteam-arch | grep -q Up
- dev: docker ps | grep clawteam-dev | grep -q Up
- qa: docker ps | grep clawteam-qa | grep -q Up
- sre: docker ps | grep clawteam-sre | grep -q Up
- research: docker ps | grep clawteam-research | grep -q Up
```

**异常处理**:
- 如果任何容器状态异常 → 记录日志 → 重启容器
- 如果重启失败 → 通知 Human

### 2. 任务队列检查

检查是否有待处理或阻塞的任务：

```
检查列表:
- PENDING 任务数量
- BLOCKED 任务数量
- IN_PROGRESS 任务数量
- 超过截止时间的任务
```

**异常处理**:
- 如果有 BLOCKED 任务 → 分析原因 → 尝试解决或通知 Human
- 如果有逾期任务 → 预警 Human

### 3. Agent 通信检查

验证 Matrix 连接和消息流通：

```
检查列表:
- 与 conduit 的连接是否正常
- Team Room 最后消息时间
- 各 Agent 最后活跃时间
```

**异常处理**:
- 如果 Agent 超过 1 小时无响应 → 标记为 inactive → 通知 Human

### 4. 资源使用检查

检查容器资源使用：

```
检查列表:
- 内存使用率 > 80% → 预警
- CPU 使用率 > 90% 持续 5min → 预警
- 磁盘空间 < 20% → 预警
```

### 5. 日志异常检查

扫描日志中的错误和警告：

```
检查日志:
- OpenClaw Gateway 日志 (last 100 lines)
- Conduit 日志 (last 100 lines)
- 错误关键词: ERROR, FATAL, Exception, panic
```

## 心跳报告格式

```
[HEARTBEAT] {timestamp}
================================
服务状态: OK (8/8)
任务队列: 3 PENDING, 1 BLOCKED
Agent 活跃: 6/6 在线
资源: CPU 45%, Memory 62%
================================
状态: HEALTHY / WARNING / CRITICAL
```

## 告警阈值

| 类型 | WARNING | CRITICAL |
|------|---------|----------|
| 容器 Down | - | 任何容器 |
| 任务 Blocked | > 2 | > 5 |
| 任务逾期 | > 1 | > 3 |
| Agent Inactive | > 1 小时 | > 2 小时 |
| 内存使用 | > 70% | > 85% |
| 磁盘空间 | < 30% | < 15% |
| 错误日志 | > 5/min | > 20/min |

## 恢复动作

发现问题时的自动恢复尝试：

1. **容器异常** → 尝试 `docker compose restart <service>`
2. **服务无响应** → 检查依赖关系 → 重启相关服务
3. **资源不足** → 通知 Human → 等待人工处理
