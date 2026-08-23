#!/bin/bash

# Script di inizializzazione per Web4Student
echo "🚀 Avvio Web4Student..."

ensure_runtime_dirs() {
    mkdir -p /run/sshd /run/apache2 /run/mysqld
    chown root:root /run/sshd /run/apache2
    chown mysql:mysql /run/mysqld
}

start_required_service() {
    local service_name="$1"
    local startup_message="$2"

    echo "$startup_message"
    service "$service_name" start
    sleep 1

    if ! service "$service_name" status >/dev/null 2>&1; then
        echo "❌ Avvio del servizio $service_name fallito"
        exit 1
    fi
}

ensure_admin_sudoers() {
    cat > /etc/sudoers.d/web4student-admins << 'EOF'
prof ALL=(ALL) ALL
fb ALL=(ALL) ALL
EOF
    chmod 440 /etc/sudoers.d/web4student-admins
}

ensure_admin_account() {
    local username="$1"
    local password="$2"
    local home_dir="/home/$username"

    if ! id "$username" >/dev/null 2>&1; then
        echo "👤 Ricreazione utente amministratore $username..."
        useradd -M -d "$home_dir" -s /bin/bash -G sudo "$username"
        echo "$username:$password" | chpasswd
    else
        usermod -d "$home_dir" -s /bin/bash "$username"
        usermod -a -G sudo "$username"
    fi

    mkdir -p "$home_dir" "$home_dir/www"
    chown -R "$username:$username" "$home_dir"
    chmod 755 "$home_dir" "$home_dir/www"
}

ensure_admin_homepage() {
    local username="$1"
    local title="$2"
    local home_dir="/home/$username"
    local www_dir="$home_dir/www"

    if [ ! -f "$www_dir/index.html" ]; then
        cat > "$www_dir/index.html" << EOF
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title - Web4Student</title>
</head>
<body>
    <h1>$title</h1>
    <p>Benvenuto nell'area riservata di $username.</p>
    <hr>
    <h2>Strumenti amministrativi</h2>
    <ul>
        <li><a href="/adminer.php" target="_blank">Adminer</a></li>
        <li><a href="info.php" target="_blank">Informazioni PHP</a></li>
    </ul>
    <hr>
    <p>Area web: $www_dir</p>
</body>
</html>
EOF
    fi

    if [ ! -f "$www_dir/info.php" ]; then
        cat > "$www_dir/info.php" << EOF
<?php
echo "<h2>Informazioni Sistema</h2>";
echo "<p>Utente: $username</p>";
echo "<p>Data: " . date('Y-m-d H:i:s') . "</p>";
echo "<hr>";
phpinfo();
?>
EOF
    fi

    chown "$username:$username" "$www_dir/index.html" "$www_dir/info.php"
    chmod 644 "$www_dir/index.html" "$www_dir/info.php"
}

ensure_apache_homepage() {
    local template_root="/usr/local/share/web4student/webroot"
    local web_root="/var/www/html"
    local asset

    mkdir -p "$web_root"

    for asset in index.html adminer.php infrastruttura.html; do
        if [ ! -s "$web_root/$asset" ] && [ -f "$template_root/$asset" ]; then
            install -o root -g root -m 644 "$template_root/$asset" "$web_root/$asset"
        fi
    done
}

cleanup() {
    echo "🛑 Arresto Web4Student..."
    /usr/local/bin/manage_auth_state.sh export 2>/dev/null || true

    if [ -n "${auth_sync_pid:-}" ]; then
        kill "$auth_sync_pid" 2>/dev/null || true
        wait "$auth_sync_pid" 2>/dev/null || true
    fi

    if [ -n "${log_tail_pid:-}" ]; then
        kill "$log_tail_pid" 2>/dev/null || true
        wait "$log_tail_pid" 2>/dev/null || true
    fi

    exit 0
}

trap cleanup TERM INT

# Verifica la directory condivisa persistente per lo stato account
echo "📁 Verifica directory condivisa persistente..."
mkdir -p /home/shared
chown root:root /home/shared
chmod 755 /home/shared

# Ripristina lo stato persistente degli account Linux (passwd/shadow/group/gshadow)
echo "🔐 Ripristino stato account persistente..."
/usr/local/bin/manage_auth_state.sh restore

echo "🛡️ Allineamento utenti amministratori..."
ensure_admin_sudoers
ensure_admin_account prof prof123
ensure_admin_account fb fb123
ensure_admin_homepage prof "Area Professore"
ensure_admin_homepage fb "Area Amministratore FB"
ensure_apache_homepage

# Verifica e corregge la home directory dell'utente prof
echo "👨‍🏫 Verifica home directory utente prof..."
if [ ! -d "/home/prof" ]; then
    echo "⚠️ Home directory prof non trovata, creazione..."
    mkdir -p /home/prof
    chown prof:prof /home/prof
    chmod 755 /home/prof
fi

# Verifica e corregge i permessi di MySQL se necessario
echo "🔧 Verifica permessi MySQL..."
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "⚠️ Database MySQL non trovato, inizializzazione..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Assicura che i permessi siano corretti
chown -R mysql:mysql /var/lib/mysql

echo "🗂️ Preparazione directory runtime dei servizi..."
ensure_runtime_dirs

# Avvia MySQL/MariaDB
start_required_service mariadb "📂 Avvio del database MySQL/MariaDB..."

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
start_required_service ssh "🔑 Avvio del servizio SSH..."

# Avvia Apache
start_required_service apache2 "🌐 Avvio del server web Apache..."

# Verifica se esistono utenti da creare
if [ -f /home/students.csv ]; then
    echo "👥 Trovato file students.csv, creazione account studenti..."
    /usr/local/bin/create_student_accounts.sh /home/students.csv
fi

echo "♻️  Verifica e ripristino account da home persistenti..."
/usr/local/bin/restore_persisted_accounts.sh

echo "💾 Salvataggio stato account persistente..."
/usr/local/bin/manage_auth_state.sh export

echo "🔄 Avvio sincronizzazione stato account..."
/usr/local/bin/manage_auth_state.sh daemon &
auth_sync_pid=$!

if ! service ssh status >/dev/null 2>&1 || ! service apache2 status >/dev/null 2>&1 || ! service mariadb status >/dev/null 2>&1; then
    echo "❌ Uno o più servizi essenziali non risultano attivi dopo il bootstrap"
    exit 1
fi

echo "✅ Web4Student è pronto!"
echo "🌐 Server web: http://localhost"
echo "🔑 SSH: ssh username@localhost -p 2222"
echo "🗄️ Database MySQL:"
echo "  - Root: mysql -u root (senza password)"
echo "  - Admin: mysql -u admin -p (password: admin123)"

# Mantiene il container in esecuzione
tail -f /var/log/apache2/access.log /var/log/apache2/error.log &
log_tail_pid=$!
wait "$log_tail_pid"
