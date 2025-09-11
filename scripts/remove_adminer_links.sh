#!/bin/bash

# Script per rimuovere tutti i link/copie di Adminer dalle directory utenti
echo "🧹 Rimozione link Adminer dalle directory utenti..."

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
            adminer_file="$www_dir/adminer.php"
            
            if [ -f "$adminer_file" ] || [ -L "$adminer_file" ]; then
                echo "  🗑️ Rimozione Adminer per: $real_username"
                rm -f "$adminer_file"
                count=$((count + 1))
                echo "    ✅ Rimosso per $real_username"
            fi
        fi
    fi
done

echo ""
echo "✅ Rimozione completata!"
echo "📊 File rimossi: $count"
echo ""
echo "🌐 Gli studenti possono usare l'istanza globale:"
echo "   https://w4s.filippobilardo.it/adminer.php"
