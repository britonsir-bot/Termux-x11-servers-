#!/data/data/com.termux/files/usr/bin/bash
STATE="$HOME/.local/state/termux-desktop"
LOG="$STATE/desktop.log"
STOP="$STATE/intentional-stop"

mkdir -p "$STATE/runtime"
chmod 700 "$STATE/runtime"
export DISPLAY=:0
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_RUNTIME_DIR="$STATE/runtime"
unset SSH_AUTH_SOCK

log() {
    printf '[%s] SUPERVISOR: %s\n' "$(date '+%F %T')" "$*" >> "$LOG"
}

log "Started, PID $$."

while [ ! -f "$STOP" ]; do
    if ! xdpyinfo >/dev/null 2>&1; then
        log "X11 unavailable; waiting."
        sleep 5
        continue
    fi

    log "Starting XFCE session."
    dbus-run-session -- xfce4-session >> "$LOG" 2>&1
    RESULT=$?
    log "XFCE exited with status $RESULT."
    [ -f "$STOP" ] || sleep 5
done

log "Intentional stop marker detected."
