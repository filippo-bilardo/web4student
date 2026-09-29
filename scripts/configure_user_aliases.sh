#!/bin/bash

# Script per generare automaticamente gli alias Apache per le directory utenti
# Questo script crea gli alias /~username per tutte le directory www degli utenti

APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
TEMP_CONF="/tmp/userdir_aliases.conf"

echo "🔧 Generazione alias Apache per directory utenti..."

# Inizializza il file temporaneo
echo "" > "$TEMP_CONF"

# Trova tutte le directory www degli utenti
find /home -name "www" -type d 2>/dev/null | while read www_dir; do
    # Estrai il nome utente dalla directory
    user_home=$(dirname "$www_dir")
    username=$(basename "$user_home" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g')
    
    if [ -n "$username" ] && [ "$username" != "www" ]; then
        echo "  📁 Configurando alias per utente: $username"
        
        # Aggiungi alias al file temporaneo
        cat >> "$TEMP_CONF" << EOF

# Alias per utente $username
Alias /~$username $www_dir
<Directory $www_dir>
    AllowOverride All
    Options Indexes FollowSymLinks MultiViews
    Require all granted
</Directory>
EOF
    fi
done

# Se ci sono alias da aggiungere, aggiornali nel virtual host
if [ -s "$TEMP_CONF" ]; then
    # Rimuovi eventuali alias esistenti
    sed -i '/# Alias per utente/,+6d' "$APACHE_CONF"
    
    # Aggiungi i nuovi alias prima della chiusura del virtual host
    sed -i '/<\/VirtualHost>/i \
# ========== USER DIRECTORY ALIASES =========='"$(cat "$TEMP_CONF")"'
# =============================================' "$APACHE_CONF"
    
    echo "✅ Alias Apache configurati per $(wc -l < "$TEMP_CONF" | awk '{print int($1/8)}') utenti"
else
    echo "⚠️  Nessuna directory utente trovata"
fi

# Pulizia
rm -f "$TEMP_CONF"

echo "🔄 Ricaricamento configurazione Apache..."
service apache2 reload 2>/dev/null || systemctl reload apache2 2>/dev/null || true

echo "✅ Configurazione alias completata!"
