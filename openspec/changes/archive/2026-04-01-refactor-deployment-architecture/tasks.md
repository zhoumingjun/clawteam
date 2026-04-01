## 1. Dockerfile

- [ ] 1.1 Add `COPY configs/agents/ /app/agents/` to `Dockerfile.openclaw`
- [ ] 1.2 Add `RUN ls /app/agents/` to verify agent configs are copied
- [ ] 1.3 Remove the `|| true` suppression on `@matrix-org/matrix-sdk-crypto-nodejs` install (or document why it's needed)

## 2. docker-compose.yml

- [ ] 2.1 Change openclaw service volume from `./volumes/openclaw-data:/root/.openclaw:rw` to `./volumes/openclaw:/root/.openclaw:rw`
- [ ] 2.2 Remove `volumes: - ./configs/agents:/app/agents:ro` from openclaw service
- [ ] 2.3 Rename the Docker volume from `openclaw-data` to `openclaw` in the volumes section (if named volumes are used)

## 3. .env file

- [ ] 3.1 Update `.env.example` to reflect simplified env vars: `MODEL_PROVIDER`, `HUMAN_PASSWORD`, `SYNAPSE_SERVER_NAME`, `SYNAPSE_REGISTRATION_SHARED_SECRET`
- [ ] 3.2 Remove `MANAGER_PASSWORD`, `ARCH_PASSWORD`, `DEV_PASSWORD`, `QA_PASSWORD`, `SRE_PASSWORD`, `RESEARCH_PASSWORD` from `.env.example`
- [ ] 3.3 Update `.env` (actual secrets) accordingly

## 4. Agent config cleanup

- [ ] 4.1 Rename `configs/agents/*/sould.md` to `SOUL.md` for all 6 agents (arch, dev, manager, qa, sre, research)
- [ ] 4.2 Delete `configs/agents/*/openclaw.json` from all agent directories (dynamic, not version controlled)
- [ ] 4.3 Update all internal references from `sould.md` to `SOUL.md` within agent config files

## 5. openclaw-startup.sh rewrite

- [ ] 5.1 Implement agent password generation: read or generate `~/.openclaw/.agent-passwords` using `openssl rand -hex 16`
- [ ] 5.2 Implement Synapse Admin API registration: nonce-based registration for all 6 agents using `SYNAPSE_REGISTRATION_SHARED_SECRET`
- [ ] 5.3 Implement token persistence: store `access_token` to `~/.openclaw/.agent-tokens`
- [ ] 5.4 Implement `openclaw.json` generation: create with `bindings` (room routing) and `mentionPatterns` for `main` agent
- [ ] 5.5 Implement Matrix channel setup: `openclaw channels add` for each agent using tokens
- [ ] 5.6 Implement agent workspace deployment: copy from `/app/agents/<name>/` to `~/.openclaw/agents/<name>/agent/` if `SOUL.md` not exists
- [ ] 5.7 Implement idempotency: all operations check existing state before acting
- [ ] 5.8 Remove hardcoded room ID `!JnzzKhxMVRCvoDRUmw:localhost` — make configurable via env var `MATRIX_ROOM_ID`

## 6. Delete legacy files

- [ ] 6.1 Delete `configs/matrix/conduit.yaml` (Conduit is deprecated, Synapse is used)
- [ ] 6.2 Delete `configs/matrix/init.sh` (replaced by startup.sh)
- [x] 6.3 Delete `openclaw/openclaw-agent-init.sh` (replaced by `openclaw-startup.sh`, removed)
- [x] 6.4 Delete `openclaw/openclaw-matrix-init.sh` (replaced by `openclaw-startup.sh`, removed)
- [ ] 6.5 Delete `volumes/openclaw-*-data/` directories if empty (unused legacy volumes)

## 7. Documentation updates

- [ ] 7.1 Update `README.md`: remove stale Conduit references, update deployment instructions with simplified .env vars
- [ ] 7.2 Update `deployment-guide.md`: replace multi-script startup with single `openclaw-startup.sh`, update volume strategy section
- [ ] 7.3 Update `CLAUDE.md`: reflect new deployment flow, remove outdated CLAUDE.md references to openclaw CLI host restrictions (still valid but context updated)
- [ ] 7.4 Update `TRACKER.md`: add SPEC-026 "重构部署架构" with this change, update service status table, update architecture section

## 8. Smoke and E2E test updates

- [ ] 8.1 Update smoke tests (`tests/smoke/run.sh`): verify new volume name `clawteam_openclaw` exists
- [x] 8.2 E2E：`tests/e2e/run.sh` 仅为 pytest 入口；已弃用 init 脚本已删除，卷名为 `volumes/openclaw`
- [ ] 8.3 Run smoke tests: `make test-smoke`
- [ ] 8.4 Run E2E tests: `make test-e2e`
