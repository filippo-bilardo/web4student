#!/bin/bash

# Script di inizializzazione per Web4Student
echo "🚀 Avvio Web4Student..."

# Verifica e corregge la home directory dell'utente prof
echo "👨‍🏫 Verifica home directory utente prof..."
if [ ! -d "/home/prof" ]; then
    echo "⚠️ Home directory prof non trovata, creazione..."
    mkdir -p /home/prof
    chown prof:prof /home/prof
    chmod 755 /home/prof
fi

# Crea directory www per prof se non esistente
if [ ! -d "/home/prof/www" ]; then
    echo "🌐 Creazione directory www per prof..."
    mkdir -p /home/prof/www
    chown prof:prof /home/prof/www
    chmod 755 /home/prof/www
    
    # Crea una homepage per il professore
    cat > /home/prof/www/index.html << 'EOF'
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Area Professore - Web4Student</title>
</head>
<body>
    <h1>👨‍🏫 Area Professore</h1>
    <p>Benvenuto nell'area riservata al professore.</p>
    <hr>
    <h2>🛠️ Strumenti Amministrativi</h2>
    <ul>
        <li><a href="/adminer.php" target="_blank">🗄️ Adminer - Gestione Database</a></li>
        <li><a href="info.php" target="_blank">ℹ️ Informazioni PHP</a></li>
    </ul>
    <hr>
    <p>Area web: /home/prof/www/</p>
</body>
</html>
EOF
    
    # Crea info.php per il professore
    cat > /home/prof/www/info.php << 'EOF'
<?php
echo "<h2>Informazioni Sistema</h2>";
echo "<p>Utente: prof (Professore)</p>";
echo "<p>Data: " . date('Y-m-d H:i:s') . "</p>";
echo "<hr>";
phpinfo();
?>
EOF
    
    chown prof:prof /home/prof/www/*
    chmod 644 /home/prof/www/*
fi

# Verifica e corregge i permessi di MySQL se necessario
echo "🔧 Verifica permessi MySQL..."
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "⚠️ Database MySQL non trovato, inizializzazione..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Assicura che i permessi siano corretti
chown -R mysql:mysql /var/lib/mysql

# Avvia MySQL/MariaDB
echo "📂 Avvio del database MySQL/MariaDB..."
service mariadb start

# Attende che MySQL sia completamente avviato
echo "⏳ Attesa avvio MySQL..."
sleep 5

# Verifica se l'utente admin esiste, se no lo crea
mysql -u root -e "SELECT User FROM mysql.user WHERE User='admin';" 2>/dev/null | grep -q admin
if [ $? -ne 0 ]; then
    echo "� Creazione utente admin MySQL..."
    mysql -u root -e "CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin123';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;"
    mysql -u root -e "CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'admin123';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"
    mysql -u root -e "FLUSH PRIVILEGES;"
fi

# Avvia SSH
echo "�🔑 Avvio del servizio SSH..."
service ssh start

# Avvia Apache
echo "🌐 Avvio del server web Apache..."
service apache2 start

# Inizializza e abilita le quote disco
echo "💾 Inizializzazione quote disco..."
quotacheck -cum / 2>/dev/null || true
quotaon / 2>/dev/null || true

# Verifica se esistono utenti da creare
if [ -f /home/students.csv ]; then
    echo "👥 Trovato file students.csv, creazione account studenti..."
    /usr/local/bin/create_student_accounts.sh /home/students.csv
fi

echo "✅ Web4Student è pronto!"
echo "🌐 Server web: http://localhost"
echo "🔑 SSH: ssh username@localhost -p 2222"
echo "🗄️ Database MySQL:"
echo "  - Root: mysql -u root (senza password)"
echo "  - Admin: mysql -u admin -p (password: admin123)"

# Mantiene il container in esecuzione
tail -f /var/log/apache2/access.log /var/log/apache2/error.log
