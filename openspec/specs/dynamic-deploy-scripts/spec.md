## Purpose

使部署脚本从 team.yaml 动态读取 Agent 名单，消除硬编码。

## Requirements

### Requirement: Parse team.yaml in shell scripts
The deployment scripts SHALL include a `parse_team_yaml()` function that reads `team.yaml` and populates the `AGENTS` variable and `DEFAULT_AGENT` variable. The parser SHALL use Python (already available in the container) to handle YAML parsing.

#### Scenario: AGENTS variable populated from team.yaml
- **WHEN** `parse_team_yaml` is called
- **THEN** `AGENTS` contains a space-separated list of agent names from `team.yaml`
- **THEN** `DEFAULT_AGENT` contains the `default_agent` value from `team.yaml`

#### Scenario: team.yaml missing
- **WHEN** `team.yaml` does not exist at the expected path
- **THEN** the script exits with a clear error message

### Requirement: Room creation uses human token
The `create_team_room_if_needed()` function SHALL use the human user's token to create the team room, instead of relying on a specific agent's token. The human account is always present regardless of team composition.

#### Scenario: Room created with human token
- **WHEN** `create_team_room_if_needed` is called
- **THEN** the room is created using the human user's access token
- **THEN** no specific agent name is hardcoded in the room creation logic

### Requirement: Invitation uses human token
The `invite_all_team_members()` function SHALL use the human user's token to invite all agents, instead of relying on a specific agent's token.

#### Scenario: All agents invited by human
- **WHEN** `invite_all_team_members` is called
- **THEN** invitations are sent using the human user's token
- **THEN** all agents from `AGENTS` variable are invited

### Requirement: Agent workspace mapping from team.yaml
The `deploy_workspaces()` and `register_openclaw_agents()` functions SHALL derive the agent-to-directory mapping from `team.yaml` and the `default_agent` field, instead of hardcoded spec strings.

#### Scenario: Workspace deployment matches team.yaml
- **WHEN** `deploy_workspaces` is called with team.yaml containing agents [arch, dev, product, qa, sre, research] and default_agent=product
- **THEN** workspaces are deployed for each agent plus "main:default"
- **THEN** the mapping is derived dynamically, not from a hardcoded string

### Requirement: Config generation reads team.yaml
The `generate_openclaw_json()` and `patch_bindings_if_room()` functions SHALL read the ROLES array from `team.yaml` instead of hardcoding it in JavaScript.

#### Scenario: openclaw.json generated from team.yaml
- **WHEN** `generate_openclaw_json` is called
- **THEN** the agents list in `openclaw.json` matches the agents defined in `team.yaml`
- **THEN** mention patterns are generated for each agent from `team.yaml`
