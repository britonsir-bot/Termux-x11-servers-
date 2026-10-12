#!/data/data/com.termux/files/usr/bin/bash
STATE="$HOME/.local/state/termux-desktop"
LOG="$STATE/desktop.log"
PIDFILE="$STATE/desktop-watchdog.pid"
STOP="$STATE/intentional-stop"
SELF=""

log() {
    printf '[%s] WATCHDOG: %s\n' "$(date '+%F %T')" "$*" >> "$LOG"
}

trap 'rm -f "$PIDFILE"; log "Watchdog exiting."; exit 0' TERM INT

echo "$$" > "$PIDFILE"
log "Started, PID $$."

while [ ! -f "$STOP" ]; do
    PID="$(cat "$STATE/xfce-supervisor.pid" 2>/dev/null || true)"

    ALIVE=0
    if [[ "$PID" =~ ^[0-9]+$ ]] && kill -0 "$PID" 2>/dev/null; then
        ARGS="$(ps -p "$PID" -o args= 2>/dev/null || true)"
        case "$ARGS" in
            *xfce-supervisor.sh*) ALIVE=1 ;;
        esac
    fi

    if [ "$ALIVE" -eq 0 ]; then
        log "Supervisor missing; requesting desktop recovery."
        "$HOME/bin/desktop" start >> "$LOG" 2>&1 || true
    fi

    sleep 5
done

rm -f "$PIDFILE"
log "Intentional stop marker detected."
