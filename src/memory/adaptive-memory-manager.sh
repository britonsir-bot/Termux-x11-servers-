#!/data/data/com.termux/files/usr/bin/bash

STATE="$HOME/.local/state/termux-desktop"
LOG="$STATE/adaptive-memory.log"
PIDFILE="$STATE/adaptive-memory.pid"
INTERVAL=30

mkdir -p "$STATE"
chmod 700 "$STATE"

memory_read() {
    awk '
    /^MemAvailable:/ { m=$2 }
    /^SwapTotal:/ { t=$2 }
    /^SwapFree:/ { f=$2 }
    END {
        if (m=="" || t=="" || f=="") exit 1
        printf "%d %d %d\n", int(m/1024), int(t/1024), int((t-f)/1024)
    }' /proc/meminfo
}

firefox_count() {
    local n=0
    for name in firefox firefox-bin firefox-esr; do
        while read -r pid; do
            [ -n "$pid" ] && n=$((n+1))
        done < <(pgrep -x "$name" 2>/dev/null || true)
    done
    echo "$n"
}

case "${1:-status}" in
start)
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "Adaptive memory manager already running."
        exit 0
    fi
    rm -f "$PIDFILE"
    nohup setsid bash "$0" monitor </dev/null >> "$LOG" 2>&1 &
    echo "$!" > "$PIDFILE"
    echo "Adaptive memory manager start requested."
    ;;

stop)
    PID="$(cat "$PIDFILE" 2>/dev/null || true)"
    if [[ "$PID" =~ ^[0-9]+$ ]]; then
        kill -TERM "$PID" 2>/dev/null || true
    fi
    echo "Stop requested."
    ;;

status)
    PID="$(cat "$PIDFILE" 2>/dev/null || true)"
    if [[ "$PID" =~ ^[0-9]+$ ]] && kill -0 "$PID" 2>/dev/null; then
        echo "Manager: running (PID $PID)"
    else
        echo "Manager: stopped"
    fi
    if V="$(memory_read)"; then
        read -r RAM TOTAL USED <<< "$V"
        echo "Available RAM: ${RAM} MiB"
        echo "Swap used: ${USED} MiB / ${TOTAL} MiB"
    fi
    echo "Firefox processes visible to Termux: $(firefox_count)"
    tail -n 5 "$LOG" 2>/dev/null || true
    ;;

monitor)
    trap 'rm -f "$PIDFILE"; exit 0' TERM INT
    echo "$$" > "$PIDFILE"
    CURRENT="UNKNOWN"
    LAST_LOG=0

    while true; do
        if V="$(memory_read 2>/dev/null)"; then
            read -r RAM TOTAL USED <<< "$V"

            case "$CURRENT" in
                CRITICAL)
                    if [ "$RAM" -lt 280 ]; then
                        NEXT="CRITICAL"
                    elif [ "$RAM" -lt 480 ]; then
                        NEXT="PRESSURE"
                    else
                        NEXT="NORMAL"
                    fi
                    ;;
                PRESSURE)
                    if [ "$RAM" -lt 220 ]; then
                        NEXT="CRITICAL"
                    elif [ "$RAM" -lt 480 ]; then
                        NEXT="PRESSURE"
                    else
                        NEXT="NORMAL"
                    fi
                    ;;
                *)
                    if [ "$RAM" -lt 220 ]; then
                        NEXT="CRITICAL"
                    elif [ "$RAM" -lt 400 ]; then
                        NEXT="PRESSURE"
                    else
                        NEXT="NORMAL"
                    fi
                    ;;
            esac

            NOW="$(date +%s)"
            if [ "$NEXT" != "$CURRENT" ] || [ $((NOW-LAST_LOG)) -ge 60 ]; then
                FF="$(firefox_count)"
                case "$NEXT" in
                    NORMAL) ACTION="normal workload; leave browser and desktop alone" ;;
                    PRESSURE) ACTION="defer optional builds and indexing" ;;
                    CRITICAL) ACTION="pause new heavy jobs; protect active work" ;;
                esac
                printf '[%s] state=%s available_ram=%sMiB swap_used=%sMiB firefox_processes_visible=%s recommendation="%s" mode=monitor-only\n' \
                    "$(date '+%F %T')" "$NEXT" "$RAM" "$USED" "$FF" "$ACTION" >> "$LOG"
                CURRENT="$NEXT"
                LAST_LOG="$NOW"
            fi
        else
            echo "[$(date '+%F %T')] ERROR: memory readings unavailable" >> "$LOG"
        fi
        sleep "$INTERVAL"
    done
    ;;

*)
    echo "Usage: $0 {start|stop|status}"
    exit 2
    ;;
esac
