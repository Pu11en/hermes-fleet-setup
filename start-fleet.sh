#!/bin/bash
# Starts the gateway for all 10 Hermes fleet agents.

for i in $(seq 1 10); do
    PROFILE="hermes-$i"
    echo "Starting gateway for $PROFILE..."
    hermes profile use "$PROFILE" 2>&1
    hermes gateway start 2>&1 &
    sleep 1
done

echo ""
echo "All gateways started. Check status with: hermes profile list"
