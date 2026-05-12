#!/bin/sh
# Self-healing wrapper around snapclient.
#
# snapclient does not exit when the ALSA device is stuck busy — it just logs
# "Device or resource busy" every 100 ms forever. That state has been observed
# on the HALPI2 when Starlink drops and reconnects: something briefly double-
# opens the vc4hdmi sink and snapclient is then locked out. A plain container
# restart clears it, so this wrapper watches snapclient's output and exits
# non-zero when the error storm appears, letting Docker's restart policy
# bring us back on a clean ALSA handle.

set -u

THRESHOLD=20          # errors required to trigger a restart
WINDOW_SEC=5          # within this many seconds
BACKOFF_SEC=2         # pause before exit, so we don't tight-loop
PATTERN="Device or resource busy"

printf '[wrapper] snapclient wrapper active (threshold=%s errors/%ss)\n' "$THRESHOLD" "$WINDOW_SEC" >&2

FIFO=$(mktemp -u)
mkfifo "$FIFO"

child_pid=
cleanup() {
    if [ -n "$child_pid" ] && kill -0 "$child_pid" 2>/dev/null; then
        kill -TERM "$child_pid" 2>/dev/null || true
    fi
    rm -f "$FIFO"
}
trap cleanup EXIT
trap 'cleanup; exit 143' TERM INT

/usr/bin/snapclient "$@" >"$FIFO" 2>&1 &
child_pid=$!

count=0
window_start=0
restart_needed=0
while IFS= read -r line; do
    printf '%s\n' "$line"
    case "$line" in
        *"$PATTERN"*)
            now=$(date +%s)
            if [ "$count" -eq 0 ] || [ $((now - window_start)) -gt "$WINDOW_SEC" ]; then
                window_start=$now
                count=1
            else
                count=$((count + 1))
            fi
            if [ "$count" -ge "$THRESHOLD" ]; then
                printf '[wrapper] %s ALSA busy errors within %ss — exiting so Docker restarts the container\n' \
                    "$count" "$WINDOW_SEC" >&2
                restart_needed=1
                break
            fi
            ;;
    esac
done < "$FIFO"

if [ "$restart_needed" -eq 1 ]; then
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
    sleep "$BACKOFF_SEC"
    exit 1
fi

wait "$child_pid"
exit $?
