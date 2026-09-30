#!/bin/bash

set -u

echo "💾 Impostazione quote disco..."

if [ -d /home ] && [ ! -f /home/aquota.user ]; then
    quotactl -x /home 2>/dev/null || true
fi
if ! quotaon -v /home 2>/dev/null; then
    echo "⚠️ /home non ha quote attive: abilitarle sul filesystem host per applicare i limiti"
fi
quotaon_status=$(quotaon -p /home 2>&1 || true)
if printf '%s\n' "$quotaon_status" | grep -q "not found or has no quota enabled"; then
    echo "ℹ️ Quote non applicate: il filesystem /home non espone quote utente"
    exit 0
fi

for username in fb prof $(getent group web4students | cut -d: -f4 | tr ',' ' '); do
    if id "$username" >/dev/null 2>&1; then
        if [[ "$username" == "fb" || "$username" == "prof" ]]; then
            setquota -u "$username" 51200 102400 0 0 /home 2>/dev/null || true
            echo "  ✅ Quota $username: 50MB soft, 100MB hard"
        else
            setquota -u "$username" 8192 10240 0 0 /home 2>/dev/null || true
            echo "  ✅ Quota $username: 8MB soft, 10MB hard"
        fi
    fi
done

echo "✅ Quote disco applicate"
