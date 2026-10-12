#!/data/data/com.termux/files/usr/bin/bash

STATE="$HOME/.local/state/termux-desktop"
LOG="$STATE/memory-scheduler.log"
PIDFILE="$STATE/memory-scheduler.pid"
INTERVAL=30

mkdir -p "$STATE"
chmod 700 "$STATE"

read_memory() {
    awk '
    /^MemAvailable:/ { mem=$2 }
    /^SwapTotal:/ { st=$2 }
    /^SwapFree:/ { sf=$2 }
    END {
        if (mem == "" || st == "" || sf == "") exit 1
        printf "%d %d %d\n", int(mem/1024), int(st/1024), int((st-sf)/1024)
    }' /proc/meminfo
}

case "${1:-status}" in
    start)
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            echo "Memory scheduler already running."
            exit 0
        fi
        rm -f "$PIDFILE"
        nohup setsid bash "$0" monitor </dev/null >> "$LOG" 2>&1 &
        echo "$!" > "$PIDFILE"
        echo "Memory scheduler start requested."
        ;;

    stop)
        PID="$(cat "$PIDFILE" 2>/dev/null || true)"
        if [[ "$PID" =~ ^[0-9]+$ ]]; then
            kill -TERM "$PID" 2>/dev/null || true
        fi
        rm -f "$PIDFILE"
        echo "Memory scheduler stop requested."
        ;;

    status)
        PID="$(cat "$PIDFILE" 2>/dev/null || true)"
        if [[ "$PID" =~ ^[0-9]+$ ]] && kill -0 "$PID" 2>/dev/null; then
            echo "Memory scheduler: running (PID $PID)"
        else
            echo "Memory scheduler: stopped"
        fi
        if read_memory; then
            read -r MEM SWAP_TOTAL SWAP_USED <<< "$(read_memory)"
            echo "Available RAM: ${MEM} MiB"
            echo "Swap used: ${SWAP_USED} MiB / ${SWAP_TOTAL} MiB"
        else
            echo "Memory readings unavailable."
        fi
        ;;

    monitor)
        trap 'rm -f "$PIDFILE"; exit 0' TERM INT
        echo "$$" > "$PIDFILE"
        LAST_STATE="UNKNOWN"
        LAST_LOG=0

        while true; do
            if VALUES="$(read_memory 2>/dev/null)"; then
                read -r MEM SWAP_TOTAL SWAP_USED <<< "$VALUES"

                if [ "$MEM" -lt 220 ]; then
                    NEW_STATE="CRITICAL"
                elif [ "$MEM" -lt 400 ]; then
                    NEW_STATE="PRESSURE"
                else
                    NEW_STATE="NORMAL"
                fi

                NOW="$(date +%s)"
                if [ "$NEW_STATE" != "$LAST_STATE" ] || [ $((NOW-LAST_LOG)) -ge 60 ]; then
                    printf '[%s] state=%s available_ram=%sMiB swap_used=%sMiB swap_total=%sMiB mode=monitor-only\n' \
                        "$(date '+%F %T')" "$NEW_STATE" "$MEM" "$SWAP_USED" "$SWAP_TOTAL" >> "$LOG"
                    LAST_STATE="$NEW_STATE"
                    LAST_LOG="$NOW"
                fi
            else
                echo "[$(date '+%F %T')] ERROR: unable to read /proc/meminfo" >> "$LOG"
            fi
            sleep "$INTERVAL"
        done
        ;;

    *)
        echo "Usage: memory-scheduler.sh {start|stop|status}"
        exit 2
        ;;
esac
