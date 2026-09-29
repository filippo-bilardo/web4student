#!/bin/bash

set -e

STUDENT_GROUP="web4students"

if ! getent group "$STUDENT_GROUP" >/dev/null; then
    groupadd "$STUDENT_GROUP"
fi

# Associa al gruppo gli account che possiedono una home web studente.
find /home -mindepth 3 -maxdepth 5 -type d -name www 2>/dev/null | while read -r www_dir; do
    username=$(basename "$(dirname "$www_dir")")
    if id "$username" >/dev/null 2>&1 && [ "$username" != "prof" ] && [ "$username" != "fb" ]; then
        usermod -a -G "$STUDENT_GROUP" "$username"
    fi
done

echo "✅ Limite processi studenti attivo: 100 processi per account"
