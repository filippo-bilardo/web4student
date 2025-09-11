#!/bin/bash

# Script per creare account studenti da file CSV
# Formato CSV: classe,cognome,nome,username

CSV_FILE="$1"

if [ ! -f "$CSV_FILE" ]; then
    echo "❌ Errore: File CSV non trovato: $CSV_FILE"
    echo "Utilizzo: $0 <file.csv>"
    exit 1
fi

echo "👥 Creazione account studenti da $CSV_FILE"

# Salta l'header del CSV se presente
tail -n +2 "$CSV_FILE" | while IFS=',' read -r classe cognome nome username; do
    # Rimuove spazi bianchi
    classe=$(echo "$classe" | xargs)
    cognome=$(echo "$cognome" | xargs) 
    nome=$(echo "$nome" | xargs)
    username=$(echo "$username" | xargs)
    
    if [ -z "$classe" ] || [ -z "$nome" ] || [ -z "$cognome" ] || [ -z "$username" ]; then
        echo "⚠️  Riga non valida: $classe,$cognome,$nome,$username"
        continue
    fi
    
    # Crea la directory di classe se non esiste
    CLASS_DIR="/home/$classe"
    if [ ! -d "$CLASS_DIR" ]; then
        mkdir -p "$CLASS_DIR"
        echo "📁 Creata directory classe: $CLASS_DIR"
    fi
    
    # Directory home dell'utente
    USER_HOME="$CLASS_DIR/$cognome.$nome"
    
    # Verifica se l'utente esiste già
    if id "$username" >/dev/null 2>&1; then
        echo "⚠️  Utente $username esiste già, salto..."
        continue
    fi
    
    # Crea l'utente con home directory personalizzata
    useradd -m -d "$USER_HOME" -s /bin/bash "$username"
    
    # Imposta la password di default
    echo "$username:student123" | chpasswd
    
    # Imposta quota disco a 10MB (10240 KB)
    # Soft limit: 8MB, Hard limit: 10MB
    setquota -u "$username" 8192 10240 0 0 /
    
    # Verifica che la quota sia stata impostata
    if quota -u "$username" >/dev/null 2>&1; then
        echo "  💾 Quota disco impostata: 10MB massimi"
    else
        echo "  ⚠️ Impossibile impostare quota disco"
    fi
    
    # Crea la directory www per lo sviluppo web
    WWW_DIR="$USER_HOME/www"
    mkdir -p "$WWW_DIR"
    
    # Crea una pagina web di esempio
    cat > "$WWW_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$nome $cognome - Classe $classe</title>
</head>
<body>
    <h1>Benvenuto/a $nome $cognome!</h1>
    <p>Questa è la tua area web personale.</p>
    <p>Classe: $classe</p>
    <p>Username: $username</p>
    <hr>
    <h2>🛠️ Strumenti Disponibili</h2>
    <ul>
        <li><a href="adminer.php" target="_blank">🗄️ Adminer Personale</a></li>
        <li><a href="/adminer.php" target="_blank">🌐 Adminer Globale</a></li>
        <li><a href="info.php" target="_blank">ℹ️ Informazioni PHP</a></li>
    </ul>
    <hr>
    <p>Puoi modificare questo file per creare il tuo sito web.</p>
    <p>File location: ~/www/index.html</p>
</body>
</html>
EOF
    
    # Crea un esempio PHP
    cat > "$WWW_DIR/info.php" << EOF
<?php
echo "<h2>Informazioni PHP</h2>";
echo "<p>Utente: $username</p>";
echo "<p>Data: " . date('Y-m-d H:i:s') . "</p>";
phpinfo();
?>
EOF
    
    # Crea link simbolico ad Adminer (invece di copiarlo)
    if [ -f /var/www/html/adminer.php ]; then
        ln -sf /var/www/html/adminer.php "$WWW_DIR/adminer.php"
        echo "  🗄️ Link ad Adminer creato per gestione database"
    else
        echo "  ⚠️ Adminer non trovato, saltando installazione"
    fi
    
    # Crea un README per l'utente
    cat > "$USER_HOME/README.txt" << EOF
Benvenuto/a $nome $cognome!

La tua home directory: $USER_HOME
Username: $username
Password iniziale: student123 (CAMBIALA al primo accesso!)

Directory web: ~/www/
Il tuo sito web sarà disponibile su: http://w4s.filippobilardo.it/~$username

Per cambiare la password:
passwd

Per sviluppo web, modifica i file in ~/www/
- index.html: pagina principale
- info.php: esempio PHP
- adminer.php: gestione database MySQL

Linguaggi disponibili:
- C/C++: gcc, g++, make, gdb
- Python: python3, pip
- Java: javac, java, maven
- JavaScript: node, npm
- PHP: php

Database MySQL/MariaDB:
- Server: localhost
- Username: $username  
- Password: ${username}123
- Database: db_$username
- Accesso: mysql -u $username -p
- Web Tool Personale: http://w4s.filippobilardo.it/~$username/adminer.php
- Web Tool Globale: http://w4s.filippobilardo.it/adminer.php

Limitazioni Sistema:
- Spazio disco: 10MB massimi (8MB soft limit)
- Per verificare utilizzo: quota -u $username

Per aiuto: man <comando> oppure <comando> --help

Buon lavoro!
EOF
    
    # Imposta i permessi corretti per Apache userdir
    # Le directory devono essere accessibili da www-data per il modulo userdir
    chown -R "$username:$username" "$USER_HOME"
    chmod 755 "$USER_HOME"                    # Home directory accessibile da Apache
    chmod 755 "$WWW_DIR"                      # Directory www accessibile  
    chmod 755 "$WWW_DIR"/*                    # File web eseguibili (per PHP)
    chmod 644 "$USER_HOME/README.txt"         # README leggibile
    
    # Imposta permessi di attraversamento per le directory padre e accesso www-data
    chmod 755 "$CLASS_DIR"                    # Directory classe accessibile
    
    # Aggiunge l'utente al gruppo www-data per compatibilità con Apache
    usermod -a -G www-data "$username"
    
    # Imposta permessi specifici per i file PHP
    find "$WWW_DIR" -name "*.php" -exec chmod 644 {} \;
    find "$WWW_DIR" -name "*.html" -exec chmod 644 {} \;
    
    # Crea database personale per l'utente
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS db_$username;"
    mysql -u root -e "CREATE USER IF NOT EXISTS '$username'@'%' IDENTIFIED BY '${username}123';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON db_$username.* TO '$username'@'%';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    
    echo "✅ Creato utente: $username ($nome $cognome) - Classe $classe"
    echo "   🏠 Home: $USER_HOME"
    echo "   🌐 Web: http://w4s.filippobilardo.it/~$username"
    echo "   🗄️ Database: db_$username"
done

echo ""
echo "🎉 Creazione account completata!"
echo "📋 Ricorda agli studenti di cambiare la password iniziale: student123"
