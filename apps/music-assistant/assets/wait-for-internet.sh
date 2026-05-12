#!/bin/sh
# Polls for internet connectivity before Music Assistant starts.
# Exits 0 once reachable, or after INTERNET_WAIT_TIMEOUT seconds (default 180),
# whichever comes first — MA always starts eventually.

TIMEOUT="${INTERNET_WAIT_TIMEOUT:-180}"
INTERVAL=5
elapsed=0

while [ "$elapsed" -lt "$TIMEOUT" ]; do
    if nc -zw5 1.1.1.1 80 2>/dev/null; then
        echo "[network-check] Internet available after ${elapsed}s."
        exit 0
    fi
    echo "[network-check] Waiting for internet... (${elapsed}s elapsed)"
    sleep "$INTERVAL"
    elapsed=$((elapsed + INTERVAL))
done

echo "[network-check] Timeout after ${TIMEOUT}s — starting MA without internet."
exit 0
