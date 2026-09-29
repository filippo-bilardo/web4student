#!/bin/bash

set -e

APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
TEMP_CONF="/tmp/userdir_aliases.conf"
CLEAN_CONF="/tmp/apache_without_user_aliases.conf"

echo "🔧 Generazione alias Apache per directory utenti..."
: > "$TEMP_CONF"

find /home -name "www" -type d 2>/dev/null | while read -r www_dir; do
    user_home=$(dirname "$www_dir")
    username=$(basename "$user_home" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g')
    [ -n "$username" ] || continue
    echo "  📁 Configurando alias per utente: $username"
    cat >> "$TEMP_CONF" << EOF

# Alias per utente $username
Alias /~$username "$www_dir"
<Directory "$www_dir">
    AllowOverride All
    Options Indexes FollowSymLinks MultiViews
    Require all granted
</Directory>
EOF
done

if [ -s "$TEMP_CONF" ]; then
    awk '
        /^# ========== USER DIRECTORY ALIASES ==========/ { skip=1; next }
        /^# =============================================$/ { skip=0; next }
        !skip { print }
    ' "$APACHE_CONF" > "$CLEAN_CONF"
    mv "$CLEAN_CONF" "$APACHE_CONF"

    awk -v aliases="$TEMP_CONF" '
        /<\/VirtualHost>/ {
            print "# ========== USER DIRECTORY ALIASES =========="
            while ((getline line < aliases) > 0) print line
            close(aliases)
            print "# ============================================="
        }
        { print }
    ' "$APACHE_CONF" > "$CLEAN_CONF"
    mv "$CLEAN_CONF" "$APACHE_CONF"
    echo "✅ Alias Apache configurati per $(grep -c '^Alias /~' "$APACHE_CONF") utenti"
else
    echo "⚠️ Nessuna directory utente trovata"
fi

rm -f "$TEMP_CONF" "$CLEAN_CONF"
service apache2 reload 2>/dev/null || true
echo "✅ Configurazione alias completata!"
