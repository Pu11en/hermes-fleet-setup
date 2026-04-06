#!/bin/bash
# Stops the gateway for all 10 Hermes fleet agents.

for i in $(seq 1 10); do
    PROFILE="hermes-$i"
    echo "Stopping gateway for $PROFILE..."
    hermes profile use "$PROFILE" 2>&1
    hermes gateway stop 2>&1 || true
done

echo ""
echo "All gateways stopped."
