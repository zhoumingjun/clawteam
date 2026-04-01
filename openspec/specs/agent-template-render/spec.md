## Purpose

从 team.yaml 自动生成 TEAM.md，替代手写团队信息文件。

## Requirements

### Requirement: TEAM.md auto-generation from team.yaml
A render script SHALL generate `TEAM.md` from `team.yaml` at deploy time. The output SHALL be written to `volumes/openclaw/TEAM.md` (runtime directory). The generated file SHALL contain:
- Team member table (name, Matrix ID, role, emoji) from `agents`
- All collaboration sections (title + text) from `collaboration`

#### Scenario: TEAM.md reflects team.yaml
- **WHEN** the render script runs with a team.yaml containing 7 agents and 4 collaboration sections
- **THEN** TEAM.md contains a table with 7 rows and 4 collaboration sections
- **THEN** Matrix IDs follow the format `@<name>:localhost`

### Requirement: Agent config files only describe themselves
Each agent's IDENTITY.md, SOUL.md, TOOLS.md, HEARTBEAT.md, MEMORY.md, and USER.md SHALL only contain information about that specific agent. No agent file SHALL hardcode references to other specific agents by name or Matrix ID.

#### Scenario: No cross-agent references in SOUL.md
- **WHEN** a new agent's SOUL.md is inspected
- **THEN** it does not contain `@manager:localhost`, `@arch:localhost`, or any other agent's Matrix ID

### Requirement: AGENTS.md references TEAM.md
Each agent's AGENTS.md SHALL instruct the agent to read TEAM.md for team member information and collaboration rules. It SHALL NOT duplicate the team roster.

#### Scenario: AGENTS.md is minimal
- **WHEN** an agent's AGENTS.md is inspected
- **THEN** it contains a reference to TEAM.md for team information
- **THEN** it does NOT contain a hardcoded list of other agents

### Requirement: BOOTSTRAP.md references TEAM.md
Each agent's BOOTSTRAP.md SHALL reference TEAM.md for knowing who to communicate with, rather than hardcoding specific agent Matrix IDs.

#### Scenario: Bootstrap uses TEAM.md
- **WHEN** an agent starts up and reads BOOTSTRAP.md
- **THEN** it knows to read TEAM.md to discover team members and communication protocols
