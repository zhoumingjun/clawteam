## Purpose

定义 team.yaml 作为 Agent 名单的唯一数据源（single source of truth）。

## Requirements

### Requirement: team.yaml format
The system SHALL use `config/agents/team.yaml` as the single source of truth for the agent roster and collaboration rules. The file SHALL have exactly three top-level keys:

```yaml
agents:         # list of agents (not including default)
projects:       # list of projects
collaboration:  # dict of title→description pairs
```

#### Scenario: Valid team.yaml with all three sections
- **WHEN** `team.yaml` contains `agents`, `projects`, and `collaboration` keys
- **THEN** the parser extracts the agent list, project list, and collaboration sections successfully

#### Scenario: Agent entry validation
- **WHEN** an agent entry has `name`, `role`, and `emoji` fields
- **THEN** the parser accepts it
- **WHEN** an agent entry is missing `name`
- **THEN** the parser rejects it with a clear error

### Requirement: agents list does not include default
The `agents` list SHALL contain only agents that need Matrix accounts (e.g., manager, product, arch, dev, qa, sre, research). The `default` agent is Gateway-internal and SHALL NOT appear in the `agents` list. It has its own independent config directory at `config/agents/default/`.

#### Scenario: Default agent is independent
- **WHEN** `team.yaml` is parsed
- **THEN** `default` does not appear in the extracted agent list
- **THEN** `config/agents/default/` exists as an independent directory

### Requirement: collaboration is freeform
The `collaboration` section SHALL be a dictionary where each key is a section title and each value is a descriptive text string. No predefined keys are required. Users can add, remove, or rename any section.

#### Scenario: Custom collaboration sections
- **WHEN** `collaboration` contains keys "沟通方式", "任务分发", "决策机制"
- **THEN** the renderer outputs three sections in TEAM.md with those titles and corresponding text

### Requirement: team.yaml follows config→copy→runtime pattern
`team.yaml` SHALL be placed in `config/agents/` (git tracked, read-only template). At deploy time, it SHALL be copied to `volumes/openclaw/team.yaml` (runtime, writable). All deployment scripts SHALL read from the runtime copy.

#### Scenario: team.yaml is copied at deploy
- **WHEN** the container starts for the first time
- **THEN** `/app/.openclaw/team.yaml` is copied to `/root/.openclaw/team.yaml`
- **THEN** deployment scripts read from `/root/.openclaw/team.yaml`

### Requirement: Password variable convention
Agent passwords SHALL follow the convention `<UPPER_NAME>_PASSWORD`. The `agent_env_password_var()` function SHALL derive the variable name dynamically from the agent name, not via a case statement.

#### Scenario: Dynamic password variable
- **WHEN** agent name is "product"
- **THEN** `agent_env_password_var "product"` returns "PRODUCT_PASSWORD"
- **WHEN** a new agent "design" is added to team.yaml
- **THEN** `agent_env_password_var "design"` returns "DESIGN_PASSWORD" without code changes
