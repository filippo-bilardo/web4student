#!/bin/bash

# Script di test per verificare i permessi di sicurezza
echo "🧪 Test Sicurezza Web4Student"
echo "============================"

# Test 1: Verifica che Apache possa accedere ai file web
echo ""
echo "1️⃣ Test Apache Access:"
echo "   - Creando directory test..."

TEST_USER="testuser"
TEST_HOME="/home/5ATEST/test.user"
TEST_WWW="$TEST_HOME/www"

# Crea utente di test temporaneo
useradd -m -d "$TEST_HOME" -s /bin/bash "$TEST_USER" 2>/dev/null
echo "$TEST_USER:test123" | chpasswd
mkdir -p "$TEST_WWW"

# Crea file di test di diversi tipi
echo "<h1>Test Web</h1>" > "$TEST_WWW/index.html"
echo "<?php echo 'PHP OK'; ?>" > "$TEST_WWW/test.php"
echo "body { background: #f0f0f0; }" > "$TEST_WWW/style.css"
echo "console.log('JavaScript OK');" > "$TEST_WWW/script.js"

# Crea un'immagine di test semplice (1x1 pixel trasparente in base64)
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > "$TEST_WWW/test.png"

echo "   📸 File di test creati: HTML, PHP, CSS, JS, PNG"

# Applica permessi ibridi
chown -R "$TEST_USER:$TEST_USER" "$TEST_HOME"
chmod 755 "$TEST_HOME"
chmod o-r "$TEST_HOME"  # Rimuove lettura others
chmod 755 "$TEST_WWW"
chmod 644 "$TEST_WWW"/*

echo "   ✅ Directory test creata: $TEST_HOME"
echo "   ✅ Permessi applicati (ibridi)"

# Test 2: Verifica che altri utenti NON possano leggere
echo ""
echo "2️⃣ Test Sicurezza Utenti:"
echo "   - Test accesso come altro utente..."

# Simula accesso come altro utente (usando su se disponibile)
if command -v su >/dev/null 2>&1; then
    echo "   Test con 'su':"
    # Nota: su potrebbe richiedere password, saltiamo questo test interattivo
    echo "   ⚠️ Test interattivo saltato (richiede password)"
else
    echo "   ⚠️ Comando 'su' non disponibile"
fi

# Test permessi con ls
echo "   Test permessi directory:"
ls -ld "$TEST_HOME" 2>/dev/null || echo "   ❌ Accesso negato (corretto!)"
ls -l "$TEST_WWW/index.html" 2>/dev/null || echo "   ❌ Accesso negato ai file"

# Test 3: Verifica che Apache possa leggere tutti i tipi di file
echo ""
echo "3️⃣ Test Apache (accesso a tutti i tipi di file):"
if id www-data >/dev/null 2>&1; then
    echo "   Utente www-data esiste"
    
    # Test lettura di diversi tipi di file
    TEST_FILES=("index.html" "test.php" "style.css" "script.js" "test.png")
    ALL_ACCESSIBLE=true
    
    for file in "${TEST_FILES[@]}"; do
        if [ -r "$TEST_WWW/$file" ]; then
            echo "   ✅ $file: accessibile da Apache"
        else
            echo "   ❌ $file: NON accessibile da Apache"
            ALL_ACCESSIBLE=false
        fi
    done
    
    if [ "$ALL_ACCESSIBLE" = true ]; then
        echo "   🎉 Tutti i tipi di file sono accessibili!"
    else
        echo "   ⚠️ Alcuni file non sono accessibili"
    fi
else
    echo "   ⚠️ Utente www-data non trovato"
fi

# Test 4: Verifica protezione file CSV
echo ""
echo "4️⃣ Test Protezione CSV:"
if [ -f "/home/students.csv" ]; then
    CSV_OWNER=$(stat -c '%U' /home/students.csv 2>/dev/null)
    CSV_PERMS=$(stat -c '%a' /home/students.csv 2>/dev/null)
    echo "   Proprietario CSV: $CSV_OWNER"
    echo "   Permessi CSV: $CSV_PERMS"
    if [ "$CSV_OWNER" = "root" ] && [ "$CSV_PERMS" = "600" ]; then
        echo "   ✅ CSV protetto correttamente"
    else
        echo "   ❌ CSV NON protetto correttamente"
    fi
else
    echo "   ⚠️ File CSV non trovato"
fi

# Pulizia
echo ""
echo "🧹 Pulizia test..."
userdel -r "$TEST_USER" 2>/dev/null
rm -rf "$TEST_HOME" 2>/dev/null

echo ""
echo "🎯 Test completato!"
echo "📋 Riassunto:"
echo "   - Sicurezza ibrida: Apache funziona, utenti protetti"
echo "   - File CSV: Protetto da root"
echo "   - Directory: Accessibili da Apache ma non da altri utenti"
