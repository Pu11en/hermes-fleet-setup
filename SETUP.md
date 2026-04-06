# Manual Fleet Setup

This guide walks through the same steps as `setup-fleet.sh` but by hand, so you understand exactly what is created and why.

---

## Step 1: Get Your Telegram Bot Tokens

1. Open Telegram and talk to [@BotFather](https://t.me/botfather)
2. Send `/newbot` and follow the prompts — do this 10 times
3. Copy each bot token. It looks like: `123456789:ABCDefGhiJKlmNoPQRsTUVwxYZ`

Keep them in a list — you'll need them in Step 3.

## Step 2: Get an OpenRouter API Key

1. Go to [openrouter.ai/keys](https://openrouter.ai/keys)
2. Generate a new key (free tier is fine to start)
3. Copy it — you'll use it in every profile's `.env`

## Step 3: Create Each Profile

For each `hermes-1` through `hermes-10`, run:

```bash
# Create the profile
hermes profile create hermes-N

# Create the per-profile GitHub auth directory
mkdir -p ~/.hermes/profiles/hermes-N/gh
```

## Step 4: Write the `.env` File

For each profile `hermes-N`, create `~/.hermes/profiles/hermes-N/.env`:

```bash
# ~/.hermes/profiles/hermes-N/.env
OPENROUTER_API_KEY=sk-or-v1_your_key_here
TELEGRAM_BOT_TOKEN=123456789:ABCDefGhiJKlmNoPQRsTUVwxYZ
TELEGRAM_ALLOWED_USERS=*
GH_CONFIG_DIR=~/.hermes/profiles/hermes-N/gh
PATH=$HOME/.local/bin:$PATH
```

**Important:** Each profile gets its own Telegram token. The `OPENROUTER_API_KEY` can be the same for all of them.

## Step 5: Write the `config.yaml`

For each profile, write `~/.hermes/profiles/hermes-N/config.yaml`:

```yaml
model:
  default: qwen/qwen3.6-plus:free
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
  api_key: ${OPENROUTER_API_KEY}
fallback_providers:
- minimax
credential_pool_strategies:
  minimax: fill_first
toolsets:
- hermes-cli
agent:
  max_turns: 200
  tool_use_enforcement: auto
  verbose: false
  reasoning_effort: medium
terminal:
  backend: local
  timeout: 180
  cwd: .
  persistent_shell: true
  lifetime_seconds: 300
browser:
  inactivity_timeout: 120
  command_timeout: 30
display:
  compact: false
  personality: kawaii
  resume_display: full
  busy_input_mode: interrupt
  streaming: true
tts:
  provider: edge
stt:
  enabled: true
  provider: local
  local:
    model: base
voice:
  record_key: ctrl+b
  max_recording_seconds: 120
  auto_tts: false
memory:
  memory_enabled: true
  user_profile_enabled: true
  memory_char_limit: 2200
  user_char_limit: 1375
  nudge_interval: 10
  flush_min_turns: 6
session_reset:
  mode: both
  idle_minutes: 1440
  at_hour: 4
group_sessions_per_user: true
_config_version: 11
platform_toolsets:
  cli:
  - browser
  - clarify
  - code_execution
  - cronjob
  - delegation
  - file
  - image_gen
  - memory
  - session_search
  - skills
  - terminal
  - todo
  - tts
  - vision
  - web
  telegram:
  - browser
  - clarify
  - code_execution
  - cronjob
  - delegation
  - file
  - image_gen
  - memory
  - session_search
  - skills
  - terminal
  - todo
  - tts
  - vision
  - web
web:
  backend: firecrawl
```

## Step 6: Write the `SOUL.md`

For each profile, create `~/.hermes/profiles/hermes-N/SOUL.md`:

```markdown
You are Hermes Agent, an intelligent AI assistant created by Nous Research.
You are helpful, knowledgeable, and direct. You assist users with a wide
range of tasks including answering questions, writing and editing code,
analyzing information, creative work, and executing actions via your tools.
You communicate clearly, admit uncertainty when appropriate, and prioritize
being genuinely useful over being verbose unless otherwise directed.
```

## Step 7: GitHub Auth — Shared vs Isolated (Optional)

**Option A: Isolated (recommended if you want different GH identities per agent)**

Each profile gets its own `GH_CONFIG_DIR` at `~/.hermes/profiles/hermes-N/gh/`. Create `~/.hermes/profiles/hermes-N/gh/hosts.yml` for each:

```yaml
version: "1"
github.com:
    users:
        YOUR_GITHUB_USERNAME:
            oauth_token: gho_your_token_here
    git_protocol: https
    user: YOUR_GITHUB_USERNAME
    oauth_token: gho_your_token_here
```

Then set `GH_CONFIG_DIR=~/.hermes/profiles/hermes-N/gh` in that profile's `.env`.

**Option B: Shared (all agents use the same GH identity)**

Put the token at `~/.hermes/gh/hosts.yml`:

```yaml
version: "1"
github.com:
    users:
        YOUR_GITHUB_USERNAME:
            oauth_token: gho_your_token_here
    git_protocol: https
    user: YOUR_GITHUB_USERNAME
    oauth_token: gho_your_token_here
```

Then set `GH_CONFIG_DIR=~/.hermes/gh` in every profile's `.env`.

**Option C: Skip GitHub auth entirely**

Leave the `gh/` directory empty with just:

```yaml
version: "1"
```

The agents simply won't be able to use `gh` natively.

## Step 8: Start the Fleet

```bash
# Start all gateways
./start-fleet.sh

# Or one by one:
hermes profile use hermes-1
hermes gateway start

# Verify
hermes profile list
```

## Step 9: Pair Your Telegram Bots

For each bot, find its pairing code:

```bash
hermes profile use hermes-1
hermes pairing telegram  # gives you a code like /pair abc123
```

Go to your Telegram bot chat, send the pairing command, and complete the pairing flow. Repeat for all 10.

## Directory Layout

After setup, your `~/.hermes/profiles/` looks like:

```
~/.hermes/profiles/
├── hermes-1/
│   ├── .env            ← has telegram token 1
│   ├── config.yaml
│   ├── SOUL.md
│   ├── auth.json
│   ├── gh/hosts.yml    ← GitHub auth for this agent
│   ├── skills/
│   ├── memories/
│   └── sessions/
├── hermes-2/
│   ├── .env            ← has telegram token 2
│   ├── config.yaml
│   └── ...
...
└── hermes-10/
```

## Per-Profile Skills

Skills are stored in `~/.hermes/profiles/hermes-N/skills/`. Each profile starts with the same base skills (the ones bundled with Hermes). To install additional skills per agent:

```bash
hermes profile use hermes-3
hermes skills install autonomous-ai-agents
```

## Customizing Individual Agents

Give an agent a different personality via its `SOUL.md`:

```bash
nano ~/.hermes/profiles/hermes-5/SOUL.md
# Change the system prompt to anything you want
hermes gateway restart --profile hermes-5
```

Or change the model per profile:

```bash
hermes profile use hermes-5
hermes model set qwen/qwen3.6-plus:free
```
