#!/bin/bash

set -euo pipefail

AUTH_STATE_ROOT="${AUTH_STATE_ROOT:-/home/shared/.web4student/auth-state}"
SYNC_INTERVAL="${AUTH_STATE_SYNC_INTERVAL:-5}"
PASSWD_STATE="$AUTH_STATE_ROOT/passwd"
SHADOW_STATE="$AUTH_STATE_ROOT/shadow"
GROUP_STATE="$AUTH_STATE_ROOT/group"
GSHADOW_STATE="$AUTH_STATE_ROOT/gshadow"
USERS_STATE="$AUTH_STATE_ROOT/users"
QUIET=0

if [ "${2:-}" = "--quiet" ]; then
    QUIET=1
fi

log() {
    if [ "$QUIET" -eq 0 ]; then
        echo "$1"
    fi
}

ensure_state_dir() {
    mkdir -p "$AUTH_STATE_ROOT"
    chown root:root /home/shared
    chmod 755 /home/shared
    chown -R root:root "$(dirname "$AUTH_STATE_ROOT")"
    chmod 700 "$(dirname "$AUTH_STATE_ROOT")"
    chmod 700 "$AUTH_STATE_ROOT"
}

export_state() {
    local tmp_dir tmp_users tmp_passwd tmp_shadow tmp_group tmp_gshadow

    ensure_state_dir

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' RETURN

    tmp_users="$tmp_dir/users"
    tmp_passwd="$tmp_dir/passwd"
    tmp_shadow="$tmp_dir/shadow"
    tmp_group="$tmp_dir/group"
    tmp_gshadow="$tmp_dir/gshadow"

    awk -F: '$3 >= 1000 && $6 ~ "^/home/" && system("[ -d \"" $6 "\" ]") == 0 { print $1 }' /etc/passwd | sort -u > "$tmp_users"

    awk -F: 'NR==FNR { managed[$1]=1; next } $1 in managed { print }' "$tmp_users" /etc/passwd > "$tmp_passwd"
    awk -F: 'NR==FNR { managed[$1]=1; next } $1 in managed { print }' "$tmp_users" /etc/shadow > "$tmp_shadow"
    awk -F: '
        NR==FNR {
            managed[$1]=1
            next
        }
        ($1 in managed) {
            print
            next
        }
        {
            split($4, members, ",")
            for (idx in members) {
                if (members[idx] in managed) {
                    print
                    next
                }
            }
        }
    ' "$tmp_users" /etc/group > "$tmp_group"
    awk -F: '
        NR==FNR {
            managed[$1]=1
            next
        }
        ($1 in managed) {
            print
            next
        }
        {
            split($4, members, ",")
            for (idx in members) {
                if (members[idx] in managed) {
                    print
                    next
                }
            }
        }
    ' "$tmp_users" /etc/gshadow > "$tmp_gshadow"

    install -o root -g root -m 600 "$tmp_users" "$USERS_STATE"
    install -o root -g root -m 644 "$tmp_passwd" "$PASSWD_STATE"
    install -o root -g shadow -m 640 "$tmp_shadow" "$SHADOW_STATE"
    install -o root -g root -m 644 "$tmp_group" "$GROUP_STATE"
    install -o root -g shadow -m 640 "$tmp_gshadow" "$GSHADOW_STATE"

    log "💾 Stato account persistente aggiornato"
}

merge_state_file() {
    local live_file="$1"
    local state_file="$2"
    local mode="$3"
    local group_name="$4"
    local tmp_file

    if [ ! -s "$state_file" ]; then
        return
    fi

    tmp_file="$(mktemp)"

    awk -F: '
        NR==FNR {
            replacement[$1]=$0
            order[++count]=$1
            next
        }
        {
            if ($1 in replacement) {
                print replacement[$1]
                restored[$1]=1
            } else {
                print
            }
        }
        END {
            for (idx=1; idx<=count; idx++) {
                key=order[idx]
                if (!(key in restored)) {
                    print replacement[key]
                }
            }
        }
    ' "$state_file" "$live_file" > "$tmp_file"

    install -o root -g "$group_name" -m "$mode" "$tmp_file" "$live_file"
    rm -f "$tmp_file"
}

restore_state() {
    if [ ! -s "$PASSWD_STATE" ]; then
        log "ℹ️  Nessuno stato account persistente trovato"
        return
    fi

    merge_state_file /etc/group "$GROUP_STATE" 644 root
    merge_state_file /etc/gshadow "$GSHADOW_STATE" 640 shadow
    merge_state_file /etc/passwd "$PASSWD_STATE" 644 root
    merge_state_file /etc/shadow "$SHADOW_STATE" 640 shadow

    log "🔐 Stato account persistente ripristinato"
}

run_daemon() {
    trap 'export_state; exit 0' TERM INT

    log "🔄 Sincronizzazione stato account attiva (${SYNC_INTERVAL}s)"

    while true; do
        sleep "$SYNC_INTERVAL"
        if ! "$0" export --quiet; then
            echo "⚠️  Errore durante la sincronizzazione dello stato account"
        fi
    done
}

case "${1:-}" in
    export)
        export_state
        ;;
    restore)
        restore_state
        ;;
    daemon)
        run_daemon
        ;;
    *)
        echo "Utilizzo: $0 {export|restore|daemon}"
        exit 1
        ;;
esac
