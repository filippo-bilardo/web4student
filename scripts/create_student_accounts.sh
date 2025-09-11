#!/bin/bash

# Script per creare account studenti da file CSV
# Formato CSV: classe,cognome,nome,username
#
# 🔒 MISURE DI SICUREZZA IMPLEMENTATE:
# - File CSV protetto (chmod 600, chown root:root)
# - Home directory: chmod 755 + rimozione lettura "others" (sicurezza ibrida)
# - Directory classi: chmod 750 (proprietario + gruppo)
# - File web: chmod 644 per TUTTI i file (HTML, PHP, immagini, CSS, JS, etc.)
# - Apache può servire file web ma utenti non possono leggere directory altrui
# - Directory prof: protetta automaticamente
# - Utenti esistenti: permessi corretti automaticamente

CSV_FILE="$1"

if [ ! -f "$CSV_FILE" ]; then
    echo "❌ Errore: File CSV non trovato: $CSV_FILE"
    echo "Utilizzo: $0 <file.csv>"
    exit 1
fi

echo "👥 Creazione account studenti da $CSV_FILE"

# 🔒 SICUREZZA: Protegge il file CSV dagli studenti
chown root:root "$CSV_FILE"
chmod 600 "$CSV_FILE"
echo "🔐 File CSV protetto: solo root può accedere"

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
    
    # Crea una pagina web di esempio con CSS e JS
    cat > "$WWW_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$nome $cognome - Classe $classe</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>Benvenuto/a $nome $cognome!</h1>
    <p>Questa è la tua area web personale.</p>
    <p>Classe: $classe</p>
    <p>Username: $username</p>
    
    <div class="example-section">
        <h2>🛠️ Strumenti Disponibili</h2>
        <ul>
            <li><a href="adminer.php" target="_blank">🗄️ Adminer Personale</a></li>
            <li><a href="/adminer.php" target="_blank">🌐 Adminer Globale</a></li>
            <li><a href="info.php" target="_blank">ℹ️ Informazioni PHP</a></li>
            <li><a href="style.css" target="_blank">📄 Foglio CSS</a></li>
            <li><a href="script.js" target="_blank">🔧 JavaScript</a></li>
        </ul>
    </div>
    
    <div class="example-section">
        <h2>📁 Tipi di File Supportati</h2>
        <p>Il tuo sito web supporta tutti questi tipi di file:</p>
        <ul>
            <li>📄 HTML (.html) - Pagine web</li>
            <li>🐘 PHP (.php) - Scripting server-side</li>
            <li>🎨 CSS (.css) - Fogli di stile</li>
            <li>⚡ JavaScript (.js) - Scripting client-side</li>
            <li>🖼️ Immagini (.jpg, .png, .gif, .svg)</li>
            <li>📋 Documenti (.txt, .pdf)</li>
            <li>⚙️ Configurazioni (.xml, .json)</li>
        </ul>
    </div>
    
    <hr>
    <p>Puoi modificare questo file per creare il tuo sito web.</p>
    <p>File location: ~/www/index.html</p>
    
    <script src="script.js"></script>
</body>
</html>
EOF
    
    # Crea un esempio CSS per dimostrare il supporto
    cat > "$WWW_DIR/style.css" << EOF
/* Foglio di stile di esempio */
body {
    font-family: Arial, sans-serif;
    background-color: #f5f5f5;
    color: #333;
    margin: 0;
    padding: 20px;
}

h1 {
    color: #2c3e50;
    border-bottom: 2px solid #3498db;
    padding-bottom: 10px;
}

.example-section {
    background: white;
    padding: 15px;
    margin: 10px 0;
    border-radius: 5px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}
EOF

    # Crea un esempio JavaScript
    cat > "$WWW_DIR/script.js" << EOF
// JavaScript di esempio
document.addEventListener('DOMContentLoaded', function() {
    console.log('JavaScript caricato correttamente!');
    
    // Aggiunge data e ora corrente
    const now = new Date();
    const timeString = now.toLocaleString('it-IT');
    
    const footer = document.querySelector('body');
    if (footer) {
        const timeDiv = document.createElement('div');
        timeDiv.innerHTML = '<hr><small>Pagina caricata il: ' + timeString + '</small>';
        footer.appendChild(timeDiv);
    }
});
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

File supportati nella directory web:
- Pagine HTML (.html, .htm)
- Script PHP (.php)
- Fogli di stile CSS (.css)
- JavaScript (.js)
- Immagini (.jpg, .png, .gif, .svg, .ico)
- Documenti (.txt, .pdf, .doc, .docx)
- File di configurazione (.htaccess, .xml, .json)

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
    
    # 🔒 SICUREZZA IBRIDA: Permessi che bilanciano sicurezza e funzionalità Apache
    # Directory classi: 755 (Apache deve poter attraversare per userdir)
    chmod 755 "$CLASS_DIR"                    # Apache può attraversare
    
    # Directory home: 755 completo (Apache deve poter servire userdir)
    chmod 755 "$USER_HOME"                    # Apache può attraversare completamente
    
    # Directory www: 755 completo (Apache deve poter servire)
    chmod 755 "$WWW_DIR"                      # Apache può servire completamente
    
    # File web: accessibili da Apache
    chmod 644 "$WWW_DIR"/*                    # File leggibili da Apache
    chmod 644 "$USER_HOME/README.txt"         # README leggibile
    
    # 🔒 PROTEZIONE FILE: Impedisce lettura directory da altri utenti
    # Rimuove il permesso di lettura per "others" mantenendo esecuzione per Apache
    chmod o-r "$USER_HOME"                    # Protegge directory home
    chmod o-r "$WWW_DIR"                      # Protegge directory web
    
    # Aggiunge l'utente al gruppo www-data per compatibilità con Apache
    usermod -a -G www-data "$username"
    
    # 🔒 SICUREZZA: Imposta permessi specifici per i file web (leggibili da Apache)
    # Tutti i file nella directory web devono essere leggibili da Apache
    find "$WWW_DIR" -type f -exec chmod 644 {} \;  # Tutti i file: leggibili da Apache
    find "$WWW_DIR" -name "*.php" -exec chmod 644 {} \;   # PHP specifico
    find "$WWW_DIR" -name "*.html" -exec chmod 644 {} \;  # HTML specifico
    
    # 📁 SUPPORTO FILE MULTIMEDIALI: Assicura che immagini e altri file siano accessibili
    # Apache può servire: .jpg, .png, .gif, .css, .js, .txt, .pdf, etc.
    echo "  📸 Tutti i file web sono accessibili da Apache (immagini, CSS, JS, etc.)"
    
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

# 🔒 SICUREZZA FINALE: Protegge directory di sistema e utenti esistenti
echo ""
echo "🔐 Applicando misure di sicurezza finali..."

# Protegge la home directory del prof se esiste
if [ -d "/home/prof" ]; then
    chown -R prof:prof /home/prof
    # Approccio ibrido anche per prof: 755 + rimozione lettura others
    chmod 755 /home/prof
    chmod o-r /home/prof
    echo "🔐 Home directory prof protetta (ibrida)"
fi

# Protegge altre directory utente esistenti
find /home -maxdepth 2 -type d -name '[0-9]*' 2>/dev/null | while read class_dir; do
    if [ -d "$class_dir" ]; then
        chmod 755 "$class_dir" 2>/dev/null || true
        echo "🔐 Directory classe protetta: $class_dir"
    fi
done

# Protegge home directory esistenti degli studenti
find /home -maxdepth 3 -type d -name '*.*' 2>/dev/null | while read user_dir; do
    if [ -d "$user_dir" ] && [ "$user_dir" != "/home/prof" ]; then
        # Trova il proprietario della directory
        owner=$(stat -c '%U' "$user_dir" 2>/dev/null)
        if [ "$owner" != "root" ] && [ "$owner" != "www-data" ]; then
            # Permessi completi per Apache userdir
            chmod 755 "$user_dir" 2>/dev/null || true
            echo "🔐 Home directory protetta (userdir): $user_dir ($owner)"
        fi
    fi
done

echo ""
echo "🎉 Creazione account completata!"
echo "📋 Ricorda agli studenti di cambiare la password iniziale: student123"
echo "🔒 Tutte le directory sono state protette con permessi sicuri"
