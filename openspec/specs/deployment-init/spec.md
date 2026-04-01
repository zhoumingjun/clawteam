## Purpose

定义部署初始化流程，包括密码自动生成和环境配置。

## Requirements

### Requirement: Agent password auto-generation

The system SHALL generate a random 32-character hex password for each agent (manager, arch, dev, qa, sre, research) during the first startup, and store these passwords in `~/.openclaw/.agent-passwords` file in the format `agent_name:password` (one per line). The file SHALL NOT be committed to version control.

#### Scenario: First startup generates passwords
- **WHEN** `openclaw-startup.sh` runs and `~/.openclaw/.agent-passwords` does not exist
- **THEN** the script SHALL generate a random password for each of the 6 agents using `openssl rand -hex 16`
- **AND** write them to `~/.openclaw/.agent-passwords`

#### Scenario: Subsequent startups reuse existing passwords
- **WHEN** `openclaw-startup.sh` runs and `~/.openclaw/.agent-passwords` already exists
- **THEN** the script SHALL read and reuse the existing passwords from that file

### Requirement: Agent Matrix registration via Admin API

The system SHALL register each agent as a Matrix user via the Synapse Admin API (`/_synapse/admin/v1/register`) using nonce-based registration, with the shared secret from the `SYNAPSE_REGISTRATION_SHARED_SECRET` environment variable. The system SHALL skip registration if the user already exists.

#### Scenario: Agent user registration succeeds
- **WHEN** `openclaw-startup.sh` attempts to register agent `@arch:localhost`
- **AND** the agent password exists in `~/.openclaw/.agent-passwords`
- **THEN** the script SHALL call the Synapse Admin API with nonce-based registration
- **AND** store the returned `access_token` in `~/.openclaw/.agent-tokens`

#### Scenario: Agent already exists skips registration
- **WHEN** `openclaw-startup.sh` attempts to register an agent user that already exists
- **THEN** the script SHALL detect the existing user (HTTP 400 + M_USER_IN_USE)
- **AND** skip registration, reusing the existing password from the password file

### Requirement: Agent token persistence

The system SHALL persist all agent Matrix `access_token` values to `~/.openclaw/.agent-tokens` file in the format `agent_name:token` (one per line). This file SHALL be used for subsequent Matrix channel setup and agent authentication.

#### Scenario: Tokens are written after registration
- **WHEN** agent registration succeeds and returns an `access_token`
- **THEN** the token SHALL be appended to `~/.openclaw/.agent-tokens`

#### Scenario: Existing tokens are read on restart
- **WHEN** `openclaw-startup.sh` runs and `~/.openclaw/.agent-tokens` already exists
- **THEN** the script SHALL read tokens from the file for Matrix channel setup

### Requirement: openclaw.json dynamic generation

The system SHALL generate `~/.openclaw/openclaw.json` at startup if it does not exist, containing the following:
- `bindings`: array with a single binding routing Matrix room messages to the `main` agent
- `mentionPatterns` on the `main` agent: `['@arch', '@dev', '@manager', '@qa', '@sre', '@research', '@main']`
- `agents.list`: references to all registered agent workspaces

#### Scenario: openclaw.json generated on first startup
- **WHEN** `~/.openclaw/openclaw.json` does not exist
- **THEN** `openclaw-startup.sh` SHALL generate the file with gateway configuration
- **AND** include `bindings` array with the Matrix room routing
- **AND** include `mentionPatterns` for the `main` agent

#### Scenario: Existing openclaw.json is preserved
- **WHEN** `~/.openclaw/openclaw.json` already exists
- **THEN** the script SHALL NOT overwrite it

### Requirement: Matrix channel auto-setup

The system SHALL enable the Matrix plugin and configure channels for each agent by calling `openclaw channels add` with the agent's Matrix user ID and the corresponding `access_token` from `~/.openclaw/.agent-tokens`.

#### Scenario: Channel configured from token
- **WHEN** an agent's `access_token` is available in `~/.openclaw/.agent-tokens`
- **THEN** `openclaw-startup.sh` SHALL call `openclaw channels add` for that agent
- **AND** use the token for authentication (not password)
- **AND** verify the channel status is "running"

### Requirement: Agent workspace registration

The system SHALL register each agent with OpenClaw Gateway by calling `openclaw agents add <name> --workspace <path>` for each agent whose `sould.md` (or `SOUL.md`) does not already exist at the workspace path, effectively deploying the agent config from the image into the persistent workspace.

#### Scenario: Agent workspace deployed from image
- **WHEN** `openclaw-startup.sh` runs for agent `dev`
- **AND** `/root/.openclaw/agents/dev/agent/SOUL.md` does not exist
- **THEN** the script SHALL copy `configs/agents/dev/` to `~/.openclaw/agents/dev/agent/`
- **AND** register the agent with `openclaw agents add dev --workspace ~/.openclaw/agents/dev/agent`

#### Scenario: Existing workspace is preserved
- **WHEN** `~/.openclaw/agents/dev/agent/SOUL.md` already exists
- **THEN** the script SHALL skip copying and preserve the existing workspace
