#!/bin/bash

set -u

failed=0
check() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        printf '✅ %s\n' "$label"
    else
        printf '❌ %s\n' "$label"
        failed=1
    fi
}

echo "🔎 Controlli Web4Student"
shell_syntax_ok=1
for script in manage.sh scripts/*.sh; do
    bash -n "$script" || shell_syntax_ok=0
done
if [ "$shell_syntax_ok" -eq 1 ]; then
    echo "✅ Sintassi script shell"
else
    echo "❌ Sintassi script shell"
    failed=1
fi
check "Configurazione Docker Compose" docker compose config --quiet
check "Container web4student in esecuzione" docker compose ps --status running --services
check "Configurazione Apache" docker compose exec -T web4student apache2ctl -t
check "Configurazione limite processi" docker compose exec -T web4student grep -q '@web4students.*nproc' /etc/security/limits.d/web4student-students.conf
check "Permessi stato autenticazione" docker compose exec -T web4student sh -c 'test ! -e /home/shared/.web4student/auth-state || test "$(stat -c %a /home/shared/.web4student/auth-state)" = 700'

echo "📊 Alias Apache:"
docker compose exec -T web4student sh -c "grep -c '^Alias /~' /etc/apache2/sites-available/000-default.conf" 2>/dev/null || echo "  Nessun alias attualmente configurato"
echo "💾 Spazio /home:"
docker compose exec -T web4student df -h /home 2>/dev/null || true

if [ "$failed" -ne 0 ]; then
    exit 1
fi
echo "✅ Controlli completati"
