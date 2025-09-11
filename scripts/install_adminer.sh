#!/bin/bash

# Script per installare Adminer per tutti gli utenti esistenti
echo "🗄️ Installazione Adminer per tutti gli utenti esistenti..."

# Verifica che Adminer sia disponibile
if [ ! -f /var/www/html/adminer.php ]; then
    echo "❌ Errore: Adminer non trovato in /var/www/html/adminer.php"
    echo "   Assicurati che il container sia stato ricostruito con la nuova immagine"
    exit 1
fi

# Conta gli utenti processati
count=0

# Trova tutti gli utenti studenti (UID >= 1001)
for user_dir in /home/*/*/; do
    if [ -d "$user_dir" ]; then
        # Estrae il nome utente dalla directory
        real_username=$(ls -ld "$user_dir" | awk '{print $3}')
        
        # Verifica che sia un utente studente (UID >= 1001)
        user_uid=$(id -u "$real_username" 2>/dev/null)
        if [ "$user_uid" -ge 1001 ] 2>/dev/null; then
            www_dir="$user_dir/www"
            
            if [ -d "$www_dir" ]; then
                echo "  📂 Installazione link Adminer per: $real_username"
                
                # Crea link simbolico ad Adminer (invece di copiarlo)
                ln -sf /var/www/html/adminer.php "$www_dir/adminer.php"
                chown -h "$real_username:$real_username" "$www_dir/adminer.php"
                
                count=$((count + 1))
                echo "    ✅ Completato per $real_username"
            else
                echo "    ⚠️ Directory www non trovata per $real_username"
            fi
        fi
    fi
done

echo ""
echo "✅ Installazione Adminer completata!"
echo "📊 Utenti processati: $count"
echo ""
echo "🌐 Gli studenti possono ora accedere a:"
echo "   https://w4s.filippobilardo.it/~username/adminer.php"
