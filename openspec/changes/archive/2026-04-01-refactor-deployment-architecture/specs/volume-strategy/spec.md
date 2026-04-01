## ADDED Requirements

### Requirement: Agent config embedded in image

The system SHALL embed all agent configuration files (`SOUL.md`, `AGENTS.md`, `identity.md`, `tools.md`, `user.md`, `memory.md`, `HEARTBEAT.md`) into the Docker image at `/app/agents/<agent_name>/`. These files SHALL be copied during `docker build` via the `Dockerfile.openclaw`.

#### Scenario: Agent config present in built image
- **WHEN** `docker build` completes for the openclaw image
- **THEN** the image SHALL contain all agent config files at `/app/agents/{manager,arch,dev,qa,sre,research}/`

#### Scenario: Agent config is read-only in image
- **WHEN** the openclaw container is running
- **THEN** `/app/agents/` SHALL be mounted as read-only (`:ro`)
- **AND** modifications to agent configs inside the container SHALL NOT persist across restarts

### Requirement: ~/.openclaw/ volume persistence

The system SHALL mount `~/.openclaw/` directory as a Docker volume at `volumes/openclaw/`, persisting all runtime state across container restarts and rebuilds. The volume SHALL contain:

- `agents/<name>/agent/` — deployed agent config files and runtime state
- `openclaw.json` — dynamic gateway configuration
- `.agent-passwords` — randomly generated agent passwords
- `.agent-tokens` — Matrix access tokens

#### Scenario: State persists across rebuild
- **WHEN** `docker compose build && docker compose up -d` runs
- **AND** the volume `clawteam_openclaw` already contains data
- **THEN** all agent state (tokens, passwords, config) SHALL be preserved
- **AND** no re-registration is required

#### Scenario: Volume contains expected structure
- **WHEN** the openclaw container has run at least once
- **THEN** `volumes/openclaw/` SHALL contain `agents/`, `openclaw.json`, `.agent-passwords`, `.agent-tokens`

### Requirement: configs/agents/ removed from volume mounts

The system SHALL NOT mount `configs/agents/` as a volume in `docker-compose.yml`. The agent configs SHALL be embedded in the image and copied to the persistent volume at startup.

#### Scenario: Agent configs not volume-mounted
- **WHEN** `docker compose config` is inspected
- **THEN** the openclaw service SHALL NOT have `./configs/agents` in its volumes
- **AND** agent configs SHALL only be available via the built image

### Requirement: Image rebuild required for config changes

When agent configuration files are modified, the system SHALL require a `docker compose build` to propagate changes into the persistent volume (since the config is copied at startup, and only if the workspace doesn't already exist).

#### Scenario: Config change requires volume cleanup
- **WHEN** an agent's `SOUL.md` is modified in `configs/agents/`
- **AND** `docker compose build` is run
- **THEN** the container restart WILL NOT automatically pick up the new config
- **AND** `docker compose down -v && docker compose up -d` SHALL be required to refresh the deployed config
