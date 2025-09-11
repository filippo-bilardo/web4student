#!/bin/bash

# Script di inizializzazione per Web4Student
echo "🚀 Avvio Web4Student..."

# Avvia MySQL/MariaDB
echo "📂 Avvio del database MySQL/MariaDB..."
service mariadb start

# Avvia SSH
echo "🔑 Avvio del servizio SSH..."
service ssh start

# Avvia Apache
echo "🌐 Avvio del server web Apache..."
service apache2 start

# Verifica se esistono utenti da creare
if [ -f /home/students.csv ]; then
    echo "👥 Trovato file students.csv, creazione account studenti..."
    /usr/local/bin/create_student_accounts.sh /home/students.csv
fi

# Correggi i permessi delle directory esistenti per Apache userdir
echo "🔧 Configurazione permessi directory utenti per Apache..."
find /home -maxdepth 2 -type d -name '[0-9]*' 2>/dev/null | while read class_dir; do
    chmod 755 "$class_dir" 2>/dev/null || true
done

find /home -maxdepth 3 -type d -name '*.* ' 2>/dev/null | while read user_dir; do
    chmod 755 "$user_dir" 2>/dev/null || true
    if [ -d "$user_dir/www" ]; then
        chmod 755 "$user_dir/www" 2>/dev/null || true
    fi
done

# Configura automaticamente gli alias Apache per le directory utenti
if [ -x /usr/local/bin/configure_user_aliases.sh ]; then
    /usr/local/bin/configure_user_aliases.sh
fi

echo "✅ Web4Student è pronto!"
echo "🌐 Server web: https://w4s.filippobilardo.it/"
echo "🔑 SSH: ssh username@163.192.115.36 -p 2222"
echo "🗄️ Database: mysql -h 163.192.115.36 -P 3307 -u username -p (password: student123)"

# Mantiene il container in esecuzione
tail -f /var/log/apache2/access.log /var/log/apache2/error.log
