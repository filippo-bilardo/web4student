#!/bin/bash

# Script per correggere la home directory dell'utente prof
echo "👨‍🏫 Correzione home directory utente prof..."

# Verifica se l'utente prof esiste
if ! id prof >/dev/null 2>&1; then
    echo "❌ Utente prof non trovato!"
    exit 1
fi

# Crea home directory se non esiste
if [ ! -d "/home/prof" ]; then
    echo "📁 Creazione home directory /home/prof..."
    mkdir -p /home/prof
    chown prof:prof /home/prof
    chmod 755 /home/prof
    echo "  ✅ Home directory creata"
else
    echo "  ✅ Home directory già esistente"
fi

# Crea directory www se non esiste
if [ ! -d "/home/prof/www" ]; then
    echo "🌐 Creazione directory www..."
    mkdir -p /home/prof/www
    chown prof:prof /home/prof/www
    chmod 755 /home/prof/www
    
    # Crea homepage per il professore
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
    <p>Accesso: <a href="https://w4s.filippobilardo.it/~prof/">https://w4s.filippobilardo.it/~prof/</a></p>
</body>
</html>
EOF
    
    # Crea info.php
    cat > /home/prof/www/info.php << 'EOF'
<?php
echo "<h2>Informazioni Sistema - Professore</h2>";
echo "<p>Utente: prof</p>";
echo "<p>Data: " . date('Y-m-d H:i:s') . "</p>";
echo "<hr>";
phpinfo();
?>
EOF
    
    # Crea link ad Adminer
    if [ -f /var/www/html/adminer.php ]; then
        ln -sf /var/www/html/adminer.php /home/prof/www/adminer.php
        echo "  🗄️ Link Adminer creato"
    fi
    
    # Imposta permessi
    chown -R prof:prof /home/prof/www
    chmod 755 /home/prof/www
    chmod 644 /home/prof/www/*
    
    echo "  ✅ Directory www creata e configurata"
else
    echo "  ✅ Directory www già esistente"
fi

# Verifica configurazione finale
if [ -d "/home/prof" ] && [ -d "/home/prof/www" ]; then
    echo ""
    echo "✅ Configurazione prof completata!"
    echo "🌐 Area web: https://w4s.filippobilardo.it/~prof/"
    echo "🔑 SSH: ssh prof@localhost -p 2222"
    echo "📊 Permessi home: $(ls -ld /home/prof | awk '{print $1 " " $3 ":" $4}')"
    echo "📊 Permessi www: $(ls -ld /home/prof/www | awk '{print $1 " " $3 ":" $4}')"
else
    echo "❌ Errore nella configurazione!"
    exit 1
fi
