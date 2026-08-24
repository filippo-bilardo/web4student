#!/bin/bash

set -euo pipefail

DEFAULT_PASSWORD="${DEFAULT_PASSWORD:-student123}"
ADMIN1="${ADMIN1:-prof}"
ADMIN2="${ADMIN2:-fb}"
DRY_RUN=0

if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
fi

MYSQL_USERS_FILE="$(mktemp)"
trap 'rm -f "$MYSQL_USERS_FILE"' EXIT

log() {
    echo "$1"
}

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '[dry-run] %s\n' "$*"
        return 0
    fi

    "$@"
}

normalize_full() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed "s/[^[:alnum:]]//g"
}

normalize_first_token() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed "s/[ _-].*$//; s/[^[:alnum:]]//g"
}

append_candidate() {
    local candidate="$1"
    local current="${2:-}"

    if [ -z "$candidate" ]; then
        return
    fi

    case "
$current
" in
        *"
$candidate
"*)
            return
            ;;
        *)
            CANDIDATES="${current}${current:+$'\n'}${candidate}"
            ;;
    esac
}

build_candidates() {
    local dir_name="$1"
    local surname_raw name_raw surname_full surname_first name_full name_first

    CANDIDATES=""

    if [[ "$dir_name" == *.* ]]; then
        surname_raw="${dir_name%%.*}"
        name_raw="${dir_name#*.}"
    else
        surname_raw="$dir_name"
        name_raw="$dir_name"
    fi

    surname_full="$(normalize_full "$surname_raw")"
    surname_first="$(normalize_first_token "$surname_raw")"
    name_full="$(normalize_full "$name_raw")"
    name_first="$(normalize_first_token "$name_raw")"

    append_candidate "${surname_full}.${name_first}" "$CANDIDATES"
    append_candidate "${surname_first}.${name_first}" "$CANDIDATES"
    append_candidate "${surname_full}.${name_full}" "$CANDIDATES"
    append_candidate "${surname_first}.${name_full}" "$CANDIDATES"
}

load_mysql_users() {
    if ! mysql -u root -Nse "SELECT DISTINCT User FROM mysql.user WHERE User NOT IN ('mysql','mariadb.sys','root','admin','PUBLIC','') ORDER BY User;" > "$MYSQL_USERS_FILE" 2>/dev/null; then
        : > "$MYSQL_USERS_FILE"
        log "⚠️  MySQL non raggiungibile: il ripristino userà solo l'inferenza dal percorso home"
    fi
}

mysql_user_exists() {
    local username="$1"
    grep -Fqx "$username" "$MYSQL_USERS_FILE"
}

resolve_username_from_home() {
    local home_dir="$1"
    local dir_name username readme_username

    username="$(getent passwd | awk -F: -v home="$home_dir" '$6 == home { print $1; exit }')"
    if [ -n "$username" ]; then
        printf '%s\n' "$username"
        return
    fi

    dir_name="$(basename "$home_dir")"
    build_candidates "$dir_name"

    while IFS= read -r username; do
        if mysql_user_exists "$username"; then
            printf '%s\n' "$username"
            return
        fi
    done <<< "$CANDIDATES"

    while IFS= read -r username; do
        if [[ "$username" =~ ^[a-z0-9._-]+$ ]]; then
            printf '%s\n' "$username"
            return
        fi
    done <<< "$CANDIDATES"

    if [ -f "$home_dir/README.txt" ]; then
        readme_username="$(sed -n 's/^Username: //p' "$home_dir/README.txt" | head -n1 | tr '[:upper:]' '[:lower:]')"
        if [[ "$readme_username" =~ ^[a-z0-9._-]+$ ]]; then
            printf '%s\n' "$readme_username"
            return
        fi
    fi
}

ensure_mysql_account() {
    local username="$1"

    if [ ! -s "$MYSQL_USERS_FILE" ]; then
        return
    fi

    run mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`db_$username\`;"
    run mysql -u root -e "CREATE USER IF NOT EXISTS '$username'@'%' IDENTIFIED BY '${username}123';"
    run mysql -u root -e "CREATE USER IF NOT EXISTS '$username'@'localhost' IDENTIFIED BY '${username}123';"
    run mysql -u root -e "GRANT ALL PRIVILEGES ON \`db_$username\`.* TO '$username'@'%';"
    run mysql -u root -e "GRANT ALL PRIVILEGES ON \`db_$username\`.* TO '$username'@'localhost';"
    run mysql -u root -e "FLUSH PRIVILEGES;"
}

fix_permissions() {
    local username="$1"
    local class_dir="$2"
    local home_dir="$3"
    local www_dir="$home_dir/www"

    run chown -R "$username:$username" "$home_dir"
    run chmod 755 "$class_dir"
    run chmod 755 "$home_dir"
    run chmod o-r "$home_dir"

    if [ -d "$www_dir" ]; then
        run chmod 755 "$www_dir"
        run chmod o-r "$www_dir"
        run find "$www_dir" -type f -exec chmod 644 {} \;
    fi

    if [ -f "$home_dir/README.txt" ]; then
        run chmod 644 "$home_dir/README.txt"
    fi
}

load_mysql_users

created=0
skipped=0
warnings=0

log "🔄 Ripristino account Linux da home persistenti..."

while IFS= read -r -d '' home_dir; do
    class_dir="$(dirname "$home_dir")"
    class_name="$(basename "$class_dir")"

    if [ "$class_name" = "$ADMIN1" ] || [ "$class_name" = "$ADMIN2" ] || [ "$class_name" = "shared" ] || [ "$class_name" = ".web4student" ]; then
        continue
    fi

    username="$(resolve_username_from_home "$home_dir")"

    if [ -z "$username" ]; then
        log "⚠️  Impossibile determinare username per $home_dir"
        warnings=$((warnings + 1))
        continue
    fi

    if getent passwd "$username" >/dev/null 2>&1; then
        existing_home="$(getent passwd "$username" | cut -d: -f6)"
        if [ "$existing_home" != "$home_dir" ]; then
            log "⚠️  Username $username già presente con home diversa ($existing_home), salto $home_dir"
            warnings=$((warnings + 1))
            continue
        fi

        log "ℹ️  Utente già presente: $username"
        skipped=$((skipped + 1))
    else
        log "👤 Ricreo utente $username -> $home_dir"
        run useradd -M -d "$home_dir" -s /bin/bash "$username"
        if [ "$DRY_RUN" -eq 0 ]; then
            echo "$username:$DEFAULT_PASSWORD" | chpasswd
        else
            printf '[dry-run] chpasswd for %s\n' "$username"
        fi
        created=$((created + 1))
    fi

    run usermod -a -G www-data "$username"
    ensure_mysql_account "$username"
    fix_permissions "$username" "$class_dir" "$home_dir"
done < <(find /home -mindepth 2 -maxdepth 2 -type d ! -path '/home/fb/*' ! -path '/home/prof/*' -print0 | sort -z)

log "✅ Ripristino completato"
log "   Account creati: $created"
log "   Account già presenti: $skipped"
log "   Avvisi: $warnings"
log "🔐 Le password Linux ripristinate usano il valore di default: $DEFAULT_PASSWORD"
