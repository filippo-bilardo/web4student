#!/bin/bash

# Script di inizializzazione per Web4Student
echo "🚀 Avvio Web4Student..."

require_admin_accounts() {
    : "${ADMIN1:?Impostare ADMIN1 nel file .env}"
    : "${ADMIN1_PWD:?Impostare ADMIN1_PWD nel file .env}"
    : "${ADMIN2:?Impostare ADMIN2 nel file .env}"
    : "${ADMIN2_PWD:?Impostare ADMIN2_PWD nel file .env}"
    : "${MYSQL_ROOT_PASSWORD:?Impostare MYSQL_ROOT_PASSWORD nel file .env}"
    : "${MYSQL_ADMIN_USER:?Impostare MYSQL_ADMIN_USER nel file .env}"
    : "${MYSQL_ADMIN_PASSWORD:?Impostare MYSQL_ADMIN_PASSWORD nel file .env}"
    : "${STUDENT_DEFAULT_PASSWORD:?Impostare STUDENT_DEFAULT_PASSWORD nel file .env}"

    if ! [[ "$ADMIN1" =~ ^[a-z_][a-z0-9_-]*$ ]] || ! [[ "$ADMIN2" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo "❌ ADMIN1 e ADMIN2 devono essere username Linux validi"
        exit 1
    fi

    if [ "$ADMIN1" = "$ADMIN2" ]; then
        echo "❌ ADMIN1 e ADMIN2 devono essere diversi"
        exit 1
    fi
}

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
    printf '%s ALL=(ALL) ALL\n%s ALL=(ALL) ALL\n' "$ADMIN1" "$ADMIN2" > /etc/sudoers.d/web4student-admins
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

restore_persistent_student_accounts() {
    echo "♻️ Ripristino automatico degli account studenti..."
    /usr/local/bin/manage_auth_state.sh restore
    /usr/local/bin/restore_persisted_accounts.sh
    /usr/local/bin/configure_user_aliases.sh
    /usr/local/bin/configure_disk_quotas.sh
    /usr/local/bin/configure_student_limits.sh
    /usr/local/bin/manage_auth_state.sh export
    echo "✅ Account studenti e alias ripristinati"
}

require_admin_accounts

cleanup() {
    echo "🛑 Arresto Web4Student..."
    if [ -n "${log_tail_pid:-}" ]; then
        kill "$log_tail_pid" 2>/dev/null || true
        wait "$log_tail_pid" 2>/dev/null || true
    fi

    exit 0
}

trap cleanup TERM INT

echo "🛡️ Allineamento utenti amministratori..."
ensure_admin_sudoers
ensure_admin_account "$ADMIN1" "$ADMIN1_PWD"
ensure_admin_account "$ADMIN2" "$ADMIN2_PWD"
ensure_admin_homepage "$ADMIN1" "Area Amministratore 1"
ensure_admin_homepage "$ADMIN2" "Area Amministratore 2"

# Verifica e corregge la home directory del primo amministratore
echo "👨‍🏫 Verifica home directory utente $ADMIN1..."
if [ ! -d "/home/$ADMIN1" ]; then
    echo "⚠️ Home directory $ADMIN1 non trovata, creazione..."
    mkdir -p "/home/$ADMIN1"
    chown "$ADMIN1:$ADMIN1" "/home/$ADMIN1"
    chmod 755 "/home/$ADMIN1"
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
mysql -u root -e "SELECT User FROM mysql.user WHERE User='$MYSQL_ADMIN_USER';" 2>/dev/null | grep -q "$MYSQL_ADMIN_USER"
if [ $? -ne 0 ]; then
    echo "👤 Creazione utente amministratore MySQL..."
    mysql -u root -e "CREATE USER IF NOT EXISTS '$MYSQL_ADMIN_USER'@'%' IDENTIFIED BY '$MYSQL_ADMIN_PASSWORD';"
    mysql -u root -e "ALTER USER '$MYSQL_ADMIN_USER'@'%' IDENTIFIED BY '$MYSQL_ADMIN_PASSWORD';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_ADMIN_USER'@'%' WITH GRANT OPTION;"
    mysql -u root -e "CREATE USER IF NOT EXISTS '$MYSQL_ADMIN_USER'@'localhost' IDENTIFIED BY '$MYSQL_ADMIN_PASSWORD';"
    mysql -u root -e "ALTER USER '$MYSQL_ADMIN_USER'@'localhost' IDENTIFIED BY '$MYSQL_ADMIN_PASSWORD';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_ADMIN_USER'@'localhost' WITH GRANT OPTION;"
    mysql -u root -e "FLUSH PRIVILEGES;"
fi
mysql -u root -e "ALTER USER '$MYSQL_ADMIN_USER'@'%' IDENTIFIED BY '$MYSQL_ADMIN_PASSWORD';"
mysql -u root -e "ALTER USER '$MYSQL_ADMIN_USER'@'localhost' IDENTIFIED BY '$MYSQL_ADMIN_PASSWORD';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Avvia SSH
start_required_service ssh "🔑 Avvio del servizio SSH..."

# Avvia Apache
start_required_service apache2 "🌐 Avvio del server web Apache..."

if ! service ssh status >/dev/null 2>&1 || ! service apache2 status >/dev/null 2>&1 || ! service mariadb status >/dev/null 2>&1; then
    echo "❌ Uno o più servizi essenziali non risultano attivi dopo il bootstrap"
    exit 1
fi

# Le home degli studenti sono persistenti, mentre /etc/passwd e /etc/shadow
# appartengono al container. Ricrea quindi gli account a ogni avvio/ricreazione.
restore_persistent_student_accounts

echo "✅ Web4Student è pronto!"
echo "🌐 Server web: http://localhost"
echo "🔑 SSH: ssh username@localhost -p 2222"
echo "🗄️ Database MySQL:"
echo "  - Root: mysql -u root (socket locale)"
echo "  - Admin: mysql -u $MYSQL_ADMIN_USER -p"

# Mantiene il container in esecuzione
tail -f /var/log/apache2/access.log /var/log/apache2/error.log &
log_tail_pid=$!
wait "$log_tail_pid"
