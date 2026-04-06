# Hermes Fleet Setup

Run 10 isolated Telegram bots powered by Hermes Agent — each with its own profile, memory, skills, and GitHub auth.

## What You Get

- **10 separate Telegram bots** that each run `hermes profile`
- Each bot has its own **isolated profile** (`hermes-1` through `hermes-10`)
- Each profile has its own **skills, memory, and session history**
- Per-profile **GitHub auth** — choose isolated (each agent has its own gh identity) or shared (all agents share one gh identity)
- **Shared `OPENROUTER_API_KEY`** so all agents can talk to the same LLM backend

## Prerequisites

- [Hermes Terminal](https://github.com/nousresearch/hermes-agent) installed
- 10 Telegram bot tokens from [@BotFather](https://t.me/botfather)
- An [OpenRouter](https://openrouter.ai) API key (free tier works)
- GitHub CLI (`gh`) installed

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/Pu11en/hermes-fleet-setup.git
cd hermes-fleet-setup

# 2. Run the setup script — it will ask for your 10 Telegram tokens
./setup-fleet.sh

# 3. Start all 10 agents
./start-fleet.sh
```

## Manual Setup

If you prefer to do it step by step, see [SETUP.md](SETUP.md).

## Managing the Fleet

```bash
# List all profiles and their gateway status
hermes profile list

# Start a specific agent's gateway
hermes profile use hermes-1
hermes gateway start

# Open a chat with a specific agent
hermes chat --profile hermes-1

# Stop a specific gateway
hermes profile use hermes-1
hermes gateway stop

# Check status of all gateways
hermes status
```

## Architecture

```
~/.hermes/
├── profiles/
│   ├── hermes-1/      ← Profile 1 (Telegram bot token 1)
│   │   ├── config.yaml
│   │   ├── .env       ← TELEGRAM_BOT_TOKEN, OPENROUTER_API_KEY, GH_CONFIG_DIR
│   │   ├── auth.json
│   │   ├── gh/        ← Per-profile GitHub auth (own hosts.yml)
│   │   ├── skills/
│   │   ├── memories/
│   │   └── sessions/
│   ├── hermes-2/      ← Profile 2 (Telegram bot token 2)
│   ...                ← (and so on for all 10)
```

## GitHub Auth: Shared vs Isolated

During setup you choose:

- **Isolated** — each agent gets its own `GH_CONFIG_DIR` at `~/.hermes/profiles/hermes-N/gh/`. Agents can have different GitHub identities. No auth conflicts between agents.
- **Shared** — all agents share one `GH_CONFIG_DIR` at `~/.hermes/gh/`. All agents use the same GitHub identity. Simpler if you just want one GH identity across the fleet.
- **Skip** — no GitHub auth configured at all. Agents simply won't be able to use `gh` natively.

The `gh` CLI inside any agent picks up its profile's credentials automatically via the `GH_CONFIG_DIR` env var set in each profile's `.env`.

## Customization

After setup, edit any profile's `~/.hermes/profiles/hermes-N/config.yaml` to change the model, personality, or tool configuration.

To give an agent a distinct personality, edit its `SOUL.md`:

```bash
nano ~/.hermes/profiles/hermes-1/SOUL.md
hermes gateway restart --profile hermes-1
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Files in This Repo

| File | Purpose |
|------|---------|
| `setup-fleet.sh` | Interactive script — asks for 10 Telegram tokens, creates all profiles |
| `start-fleet.sh` | Starts the gateway for all 10 agents |
| `stop-fleet.sh` | Stops all gateways |
| `SETUP.md` | Step-by-step manual setup guide |
| `TROUBLESHOOTING.md` | Common issues and fixes |
| `templates/config.yaml` | Base config used for all profiles |
| `templates/.env` | Base env template |

## Requirements

- Python 3.11+
- `uv` package manager
- `gh` CLI
- Hermes Agent v0.6+
