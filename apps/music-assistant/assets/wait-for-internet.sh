#!/bin/sh
# Waits for internet connectivity before Music Assistant starts.
# Signals readiness by touching /tmp/ready (polled by the service healthcheck).
# Never exits — stays alive so restart: unless-stopped doesn't cause a restart loop.

TIMEOUT="${INTERNET_WAIT_TIMEOUT:-180}"
INTERVAL=5
elapsed=0

while [ "$elapsed" -lt "$TIMEOUT" ]; do
    if nc -zw5 1.1.1.1 80 2>/dev/null; then
        echo "[network-check] Internet available after ${elapsed}s."
        touch /tmp/ready
        while true; do sleep 3600; done
    fi
    echo "[network-check] Waiting for internet... (${elapsed}s elapsed)"
    sleep "$INTERVAL"
    elapsed=$((elapsed + INTERVAL))
done

echo "[network-check] Timeout after ${TIMEOUT}s — starting MA without internet."
touch /tmp/ready
while true; do sleep 3600; done
