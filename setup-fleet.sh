#!/bin/bash
# ============================================================================
# Hermes Fleet Setup Script
# ============================================================================
# Creates 10 isolated Hermes profiles, one per Telegram bot token.
# Prompts interactively for:
#   - 10 Telegram bot tokens
#   - OpenRouter API key
#   - Optional: GitHub token for per-profile gh auth
#
# Usage:
#   ./setup-fleet.sh
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PROFILE_COUNT=10
HERMES_DIR="$HOME/.hermes"
PROFILES_DIR="$HERMES_DIR/profiles"

# ============================================================================
# Helpers
# ============================================================================

err()  { echo -e "${RED}✗ $*${NC}" >&2; }
ok()   { echo -e "${GREEN}✓ $*${NC}"; }
info() { echo -e "${CYAN}→ $*${NC}"; }
warn() { echo -e "${YELLOW}! $*${NC}"; }
step() { echo -e "\n${BOLD}[$1] $*${NC}"; }

ask() {
    local prompt="$1"
    local var_name="$2"
    local valid="$3"  # optional: regex to validate
    local value

    while true; do
        echo -n -e "${CYAN}${prompt}${NC}  "
        read -r value
        if [ -z "$valid" ]; then
            break
        fi
        if echo "$value" | grep -qE "$valid"; then
            break
        fi
        err "Invalid format. Expected: $valid"
    done
    printf -v "$var_name" '%s' "$value"
}

ask_pass() {
    local prompt="$1"
    local var_name="$2"
    echo -n -e "${CYAN}${prompt}${NC}  "
    read -rs $var_name
    echo
}

mask_token() {
    local tok="$1"
    if [ ${#tok} -le 8 ]; then
        echo "****"
    else
        echo "${tok:0:6}...${tok: -4}"
    fi
}

# ============================================================================
# Banner
# ============================================================================

echo ""
echo -e "${CYAN}   _   _ _           _     ______   ___  ___"
echo -e "${CYAN}  | \ | (_)         (_)    | ___ \ / _ \ / _ |"
echo -e "${CYAN}  |  \| |_ ___  __ _ _ _ __| |_/ // /_\ \ / /|"
echo -e "${CYAN}  | . \` | / __|/ _\` | | '__|  __/ |  _  | | | |"
echo -e "${CYAN}  | |\  | \__ \ (_| | | |  | |    | | | | |_| |"
echo -e "${CYAN}  \_| \_|_|___/\__,_|_|_|  \_|    \_| |_/\___/"
echo -e "${CYAN}                                              "
echo -e "${CYAN}          F L E E T   S E T U P${NC}"
echo ""

# ============================================================================
# Check prerequisites
# ============================================================================

step "1" "Checking prerequisites"
if ! command -v hermes &>/dev/null; then
    err "Hermes is not installed or not in PATH."
    info "Install it from: https://github.com/nousresearch/hermes-agent"
    exit 1
fi
ok "hermes found"

if ! command -v gh &>/dev/null; then
    warn "gh CLI not found. You won't be able to use GitHub auth inside agents."
    info "Install from: https://cli.github.com"
    GH_AVAILABLE=false
else
    GH_AVAILABLE=true
    ok "gh CLI found"
fi

# ============================================================================
# Collect tokens
# ============================================================================

step "2" "Collecting Telegram bot tokens"

declare -a TELEGRAM_TOKENS
for i in $(seq 1 $PROFILE_COUNT); do
    num=$(printf "%02d" $i)
    ask "Telegram bot token for hermes-$i (get it from @BotFather):" token "^[0-9]+:[A-Za-z0-9_-]+$"
    TELEGRAM_TOKENS[$i]="$token"
    ok "hermes-$i: $(mask_token "${TELEGRAM_TOKENS[$i]}")"
done

# ============================================================================
# OpenRouter API Key
# ============================================================================

step "3" "OpenRouter API Key"

if [ -n "$OPENROUTER_API_KEY" ]; then
    info "Using OPENROUTER_API_KEY from environment"
    OR_KEY="$OPENROUTER_API_KEY"
else
    ask "OpenRouter API key (get it from https://openrouter.ai/keys):" OR_KEY "^sk-or-v[A-Za-z0-9_-]+$"
fi
ok "OpenRouter key set: $(mask_token "$OR_KEY")"

# ============================================================================
# GitHub Token (optional)
# ============================================================================

step "4" "GitHub Token (optional)"
echo "  Each Hermes profile can have its own GitHub auth directory."
echo "  You can skip this and share a single GitHub token across all agents,"
echo "  or set per-profile tokens later."
echo ""
if [ "$GH_AVAILABLE" = true ]; then
    read -p "  Enter a GitHub personal access token (or press Enter to skip): " -r GH_TOKEN
    if [ -z "$GH_TOKEN" ]; then
        GH_TOKEN=""
        info "Skipping GitHub auth — agents won't be able to use gh natively"
    else
        GH_TOKEN_SET=true
    fi
else
    GH_TOKEN=""
fi

# ============================================================================
# Create base .env and config.yaml templates
# ============================================================================

step "5" "Creating Hermes profiles"

mkdir -p "$PROFILES_DIR"

# Template .env (token placeholder will be substituted per profile)
BASE_ENV="# Hermes Fleet Profile
OPENROUTER_API_KEY=${OR_KEY}
TELEGRAM_BOT_TOKEN=CHANGEME
TELEGRAM_ALLOWED_USERS=*
GH_CONFIG_DIR=\${HERMES_DIR}/profiles/hermes-N/gh
PATH=\${HOME}/.local/bin:\${PATH}
"

# Template config.yaml
BASE_CONFIG='model:
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
  record_sessions: false
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
'

# SOUL.md template
BASE_SOUL='You are Hermes Agent, an intelligent AI assistant created by Nous Research. You are helpful, knowledgeable, and direct. You assist users with a wide range of tasks including answering questions, writing and editing code, analyzing information, creative work, and executing actions via your tools. You communicate clearly, admit uncertainty when appropriate, and prioritize being genuinely useful over being verbose unless otherwise directed below.
'

# ============================================================================
# Create each profile
# ============================================================================

for i in $(seq 1 $PROFILE_COUNT); do
    PROFILE_NAME="hermes-$i"
    PROFILE_DIR="$PROFILES_DIR/$PROFILE_NAME"

    step "5.$i" "Creating profile: $PROFILE_NAME"

    # Create profile using hermes CLI
    if [ -d "$PROFILE_DIR" ]; then
        warn "$PROFILE_NAME already exists — skipping profile creation"
    else
        hermes profile create "$PROFILE_NAME" 2>&1 || true
    fi

    # Write .env with the correct token
    TOKEN="${TELEGRAM_TOKENS[$i]}"
    ENV_CONTENT=$(echo "$BASE_ENV" | sed "s/CHANGEME/$TOKEN/" | sed "s/hermes-N/$PROFILE_NAME/g")
    echo "$ENV_CONTENT" > "$PROFILE_DIR/.env"

    # Write config.yaml
    echo "$BASE_CONFIG" > "$PROFILE_DIR/config.yaml"

    # Write SOUL.md
    echo "$BASE_SOUL" > "$PROFILE_DIR/SOUL.md"

    # Create per-profile gh directory and auth
    GH_DIR="$PROFILE_DIR/gh"
    mkdir -p "$GH_DIR"

    if [ -n "$GH_TOKEN" ] && [ "$GH_TOKEN_SET" = true ]; then
        # Configure gh for this profile
        GH_CONFIG_DIR="$GH_DIR" gh auth status &>/dev/null || \
            echo "$GH_TOKEN" | GH_CONFIG_DIR="$GH_DIR" gh auth login --with-token 2>/dev/null || true

        # Write hosts.yml for this profile
        cat > "$GH_DIR/hosts.yml" << EOF
version: "1"
github.com:
    users:
        $(gh api user --jq '.login' 2>/dev/null || echo "user"):
            oauth_token: $GH_TOKEN
    git_protocol: https
    user: $(gh api user --jq '.login' 2>/dev/null || echo "user")
    oauth_token: $GH_TOKEN
EOF
        ok "$PROFILE_NAME: gh auth configured"
    else
        # Create empty gh config
        cat > "$GH_DIR/hosts.yml" << EOF
version: "1"
EOF
    fi

    ok "$PROFILE_NAME: profile ready at $PROFILE_DIR"
done

# ============================================================================
# Final status
# ============================================================================

step "6" "Done!"
echo ""
ok "All $PROFILE_COUNT profiles created."
echo ""
echo "  To start all agents:"
echo "    ./start-fleet.sh"
echo ""
echo "  To start a specific agent:"
echo "    hermes profile use hermes-1"
echo "    hermes gateway start"
echo "    hermes chat"
echo ""
echo "  To list all profiles:"
echo "    hermes profile list"
echo ""
