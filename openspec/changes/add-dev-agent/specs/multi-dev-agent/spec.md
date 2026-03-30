## ADDED Requirements

### Requirement: Dev Agent 服务部署

`openclaw-agent-dev` 服务 SHALL 通过 docker-compose 启动。

### Requirement: Dev Agent Matrix 连接

Dev Agent SHALL 通过 Matrix channel 连接到 Synapse，状态为 running。

### Requirement: Dev Agent Gateway RPC

Gateway SHALL 能接收 RPC 调用并转发给 Dev Agent。

### Requirement: Matrix 通知发送

Dev Agent SHALL 能通过 Matrix channel 发送通知消息。

### Requirement: 多 Agent 配置分离

Dev Agent SHALL 有独立的配置目录和 volume。

## Matrix Room Setup (SPEC-022)

### Registered Matrix Users

| User ID | Display Name | Purpose |
|---------|--------------|---------|
| @openclaw-agent:localhost | openclaw-agent | Manager Agent (primary) |
| @openclaw-agent-dev:localhost | openclaw-agent-dev | Dev Agent |
| @arch:localhost | arch | Architecture Agent |
| @dev:localhost | dev | Development Agent |
| @qa:localhost | qa | QA Agent |
| @sre:localhost | sre | SRE Agent |
| @research:localhost | research | Research Agent |
| @human:localhost | human | Human user |

### Matrix Rooms

| Room ID | Room Name | Purpose | Members |
|---------|-----------|---------|---------|
| !zfNrpyWgojlkJcigrf:localhost | Claw Team | Main collaboration room for all users and agents | 9 |
| !dZvtMsoEkcegNIyzHS:localhost | clawteam-agents | Agent-to-agent communication (private, invite-only) | 7 |

### Room Configuration

#### Claw Team (Main Room)
- **Purpose**: General discussion, human-agent interaction, notifications
- **Visibility**: Private
- **Members**: All registered users (@human, @manager, @dev, @arch, @qa, @sre, @research, @openclaw-agent, @openclaw-agent-dev)

#### clawteam-agents (Agents Room)
- **Purpose**: Inter-agent communication, coordination between specialized agents
- **Visibility**: Private (invite-only)
- **Members**: All agent accounts (@openclaw-agent, @openclaw-agent-dev, @arch, @dev, @qa, @sre, @research)
- **Room ID**: `!dZvtMsoEkcegNIyzHS:localhost`

### Bot Account Access Tokens

| Agent | Access Token | Device ID |
|-------|--------------|------------|
| Manager (openclaw-agent) | `syt_b3BlbmNsYXctYWdlbnQ_NUgKApthWLpxXTTXrxSM_3XmRm1` | BBZLTJMEQR |
| Dev (openclaw-agent-dev) | `syt_b3BlbmNsYXctYWdlbnQtZGV2_ISItMdEgeaDibETlEiXz_3N9bia` | NZZEKTQGJT |
