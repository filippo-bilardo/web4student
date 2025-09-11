#!/bin/bash

# Script per verificare lo stato di MySQL/MariaDB
echo "🔍 Verifica stato MySQL/MariaDB..."

# Verifica se il servizio è in esecuzione
if pgrep -x "mariadbd" > /dev/null; then
    echo "✅ MySQL/MariaDB è in esecuzione"
    
    # Verifica connessione come root
    if mysql -u root -e "SELECT VERSION();" >/dev/null 2>&1; then
        echo "✅ Connessione root funzionante"
        mysql -u root -e "SELECT VERSION();"
    else
        echo "❌ Errore connessione root"
    fi
    
    # Verifica connessione come admin
    if mysql -u admin -padmin123 -e "SELECT USER();" >/dev/null 2>&1; then
        echo "✅ Connessione admin funzionante"
    else
        echo "❌ Errore connessione admin"
    fi
    
    # Mostra databases disponibili
    echo "📂 Database disponibili:"
    mysql -u root -e "SHOW DATABASES;"
    
else
    echo "❌ MySQL/MariaDB non è in esecuzione"
    echo "🔧 Per avviarlo: service mariadb start"
fi

# Verifica permessi directory
echo "🔒 Permessi directory MySQL:"
ls -la /var/lib/ | grep mysql
