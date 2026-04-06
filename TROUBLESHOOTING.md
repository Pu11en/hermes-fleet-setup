# Troubleshooting

## Gateway won't start

```bash
hermes profile use hermes-1
hermes gateway start --verbose 2>&1
```

Common causes:
- `.env` file missing or malformed — check for stray whitespace
- Telegram token is invalid or already in use by another process
- Port conflict — each gateway uses a different port; check `gateway_state.json`

## "Profile not found"

Make sure you're using the right profile name:

```bash
hermes profile list
```

## Telegram bot not responding

1. Check the bot's chat with [@BotFather](https://t.me/botfather) — send `/mybots` to see your bots
2. Make sure the bot was successfully created and the token is correct in `.env`
3. Verify the gateway is running: `hermes profile list`
4. Check logs: `cat ~/.hermes/profiles/hermes-1/logs/*.log`

## gh auth not working inside an agent

Each profile has its own `GH_CONFIG_DIR`. Verify:

```bash
cat ~/.hermes/profiles/hermes-1/gh/hosts.yml
GH_CONFIG_DIR=~/.hermes/profiles/hermes-1/gh gh auth status
```

If it shows "not logged in", re-authenticate:

```bash
GH_CONFIG_DIR=~/.hermes/profiles/hermes-1/gh gh auth login
```

## Token errors with OpenRouter

Make sure your `.env` has the exact key from openrouter.ai/keys — it starts with `sk-or-v1`.

## Multiple agents responding to the same message

Set `TELEGRAM_ALLOWED_USERS=*` to allow anyone, or specify exact user IDs:

```
TELEGRAM_ALLOWED_USERS=123456789,987654321
```

## Gateway port conflicts

If two profiles try to use the same port, edit `~/.hermes/profiles/hermes-N/config.yaml` and set a different port under `gateway:`. Check the current port in `gateway_state.json`.

## Resetting a profile

```bash
hermes profile delete hermes-1
hermes profile create hermes-1
# then re-run setup for that profile only
```

## Restarting after a reboot

```bash
./start-fleet.sh
```

## Memory growing too large

Each profile accumulates memories and sessions independently. To trim:

```bash
hermes sessions prune --profile hermes-1
hermes profile use hermes-1
# then clear memories manually if needed
```
