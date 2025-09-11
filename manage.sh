#!/bin/bash

# Script di gestione Web4Student
# Versione: 1.0

show_usage() {
    echo "🎓 Web4Student - Script di gestione"
    echo ""
    echo "Utilizzo: $0 <comando> [opzioni]"
    echo ""
    echo "Comandi disponibili:"
    echo "  start             - Avvia il container"
    echo "  stop              - Ferma il container"
    echo "  restart           - Riavvia il container"
    echo "  build             - Ricostruisce l'immagine"
    echo "  logs              - Mostra i log del container"
    echo "  shell             - Accede alla shell del container"
    echo "  status            - Mostra lo stato del container"
    echo "  create-users      - Crea utenti dal file students.csv"
    echo "  configure-aliases - Riconfigura alias Apache per utenti esistenti"
    echo "  fix-permissions   - Corregge i permessi delle directory utenti"
    echo "  fix-prof-home     - Corregge home directory utente prof"
    echo "  mysql-status      - Verifica stato MySQL/MariaDB"
    echo "  mysql-fix         - Corregge problemi MySQL"
    echo "  mysql-root        - Accede a MySQL come root"
    echo "  mysql-admin       - Accede a MySQL come admin"
    echo "  apply-quotas      - Applica quote disco a tutti gli utenti"
    echo "  check-quotas      - Verifica quote disco utilizzate"
    echo "  reset-quota       - Reimposta quota per un utente specifico"
    echo "  install-adminer   - Installa Adminer per tutti gli utenti esistenti"
    echo "  remove-adminer    - Rimuove link Adminer dalle directory utenti"
    echo "  clean             - Rimuove container e immagini"
    echo "  backup            - Crea backup delle home directory"
    echo "  restore           - Ripristina backup delle home directory"
    echo ""
    echo "Esempi:"
    echo "  $0 start"
    echo "  $0 create-users"
    echo "  $0 configure-aliases"
    echo "  $0 fix-permissions"
    echo "  $0 fix-prof-home"
    echo "  $0 apply-quotas"
    echo "  $0 check-quotas"
    echo "  $0 install-adminer"
    echo "  $0 reset-quota mario.rossi"
    echo "  $0 shell"
}

case "$1" in
    start)
        echo "🚀 Avvio Web4Student..."
        docker compose up -d
        echo "✅ Container avviato!"
        echo "🌐 Web: http://localhost:8080"
        echo "🔑 SSH: ssh prof@localhost -p 2222"
        echo "🗄️ MySQL: mysql -h localhost -P 3307 -u admin -p"
        ;;
    
    stop)
        echo "⏹️  Arresto Web4Student..."
        docker compose down
        echo "✅ Container arrestato!"
        ;;
    
    restart)
        echo "🔄 Riavvio Web4Student..."
        docker compose restart
        echo "✅ Container riavviato!"
        ;;
    
    build)
        echo "🔨 Ricostruzione immagine Web4Student..."
        docker compose build --no-cache
        echo "✅ Immagine ricostruita!"
        ;;
    
    logs)
        echo "📋 Log del container Web4Student:"
        docker compose logs -f web4student
        ;;
    
    shell)
        echo "🐚 Accesso alla shell del container..."
        docker compose exec web4student /bin/bash
        ;;
    
    status)
        echo "📊 Status dei container:"
        docker compose ps
        echo ""
        echo "📊 Status dei servizi nel container:"
        docker compose exec web4student service --status-all 2>/dev/null || echo "Container non in esecuzione"
        ;;
    
    create-users)
        echo "👥 Creazione utenti dal file students.csv..."
        if [ ! -f "volumes/students.csv" ]; then
            echo "❌ File students.csv non trovato!"
            exit 1
        fi
        docker compose exec web4student /usr/local/bin/create_student_accounts.sh /home/students.csv
        echo "🔧 Configurazione alias Apache..."
        docker compose exec web4student /usr/local/bin/configure_user_aliases.sh
        echo "✅ Utenti creati e configurati!"
        ;;
    
    configure-aliases)
        echo "🔧 Riconfigurazione alias Apache per utenti esistenti..."
        docker compose exec web4student /usr/local/bin/configure_user_aliases.sh
        echo "✅ Alias riconfigurati!"
        ;;
    
    fix-permissions)
        echo "🔧 Correzione permessi directory utenti..."
        docker exec web4student find /home -type d -name "www" -exec chmod 755 {} \;
        docker exec web4student find /home -name "*.html" -exec chmod 644 {} \;
        docker exec web4student find /home -name "*.php" -exec chmod 644 {} \;
        echo "✅ Permessi corretti!"
        ;;
    
    fix-prof-home)
        echo "👨‍🏫 Correzione home directory prof..."
        docker exec web4student bash -c '
            if [ ! -d "/home/prof" ]; then
                echo "❌ Home directory /home/prof non esiste, creando..."
                mkdir -p /home/prof
                chown prof:prof /home/prof
                chmod 755 /home/prof
                echo "✅ Home directory /home/prof creata"
            else
                echo "✅ Home directory /home/prof già esiste"
            fi
            
            # Crea file di configurazione base se non esistono
            if [ ! -f "/home/prof/.bashrc" ]; then
                echo "📝 Creazione file di configurazione..."
                cp /etc/skel/.* /home/prof/ 2>/dev/null || true
                chown prof:prof /home/prof/.* 2>/dev/null || true
                echo "✅ File di configurazione creati"
            fi
            
            # Crea directory www se non esiste
            if [ ! -d "/home/prof/www" ]; then
                echo "🌐 Creazione directory www per prof..."
                mkdir -p /home/prof/www
                chown prof:prof /home/prof/www
                chmod 755 /home/prof/www
            fi
            
            echo "✅ Home directory prof configurata correttamente!"
        '
        ;;
    
    mysql-status)
        echo "🔍 Verifica stato MySQL/MariaDB..."
        docker compose exec web4student /usr/local/bin/mysql_status.sh
        ;;
    
    mysql-fix)
        echo "🔧 Correzione problemi MySQL..."
        docker compose exec web4student bash -c "
            chown -R mysql:mysql /var/lib/mysql
            if [ ! -d '/var/lib/mysql/mysql' ]; then
                mysql_install_db --user=mysql --datadir=/var/lib/mysql
            fi
            service mariadb restart
            sleep 3
            mysql -u root -e 'CREATE USER IF NOT EXISTS \"admin\"@\"%\" IDENTIFIED BY \"admin123\";'
            mysql -u root -e 'GRANT ALL PRIVILEGES ON *.* TO \"admin\"@\"%\" WITH GRANT OPTION;'
            mysql -u root -e 'FLUSH PRIVILEGES;'
        "
        echo "✅ MySQL corretto!"
        ;;
    
    mysql-root)
        echo "🗄️ Accesso MySQL come root..."
        docker compose exec web4student mysql -u root
        ;;
    
    mysql-admin)
        echo "🗄️ Accesso MySQL come admin..."
        docker compose exec web4student mysql -u admin -padmin123
        ;;
    
    clean)
        echo "🧹 Pulizia completa..."
        read -p "⚠️  Sei sicuro? Questo rimuoverà tutti i container e le immagini. (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose down --rmi all --volumes --remove-orphans
            echo "✅ Pulizia completata!"
        else
            echo "❌ Operazione annullata."
        fi
        ;;
    
    backup)
        echo "💾 Backup delle home directory..."
        BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        cp -r volumes/home/* "$BACKUP_DIR/" 2>/dev/null || true
        tar -czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
        rm -rf "$BACKUP_DIR"
        echo "✅ Backup creato: ${BACKUP_DIR}.tar.gz"
        ;;
    
    restore)
        if [ -z "$2" ]; then
            echo "❌ Specifica il file di backup da ripristinare"
            echo "Utilizzo: $0 restore <backup.tar.gz>"
            exit 1
        fi
        echo "📥 Ripristino backup: $2..."
        tar -xzf "$2"
        BACKUP_DIR=$(basename "$2" .tar.gz)
        cp -r "$BACKUP_DIR"/* volumes/home/
        rm -rf "$BACKUP_DIR"
        echo "✅ Backup ripristinato!"
        ;;
    
    apply-quotas)
        echo "💾 Applicazione quote disco (10MB per utente)..."
        docker exec web4student /usr/local/bin/apply_quotas.sh
        ;;
    
    check-quotas)
        echo "🔍 Verifica quote disco..."
        docker exec web4student repquota / 2>/dev/null || echo "⚠️ Sistema quote non attivo"
        ;;
    
    reset-quota)
        if [ -z "$2" ]; then
            echo "❌ Specifica l'username per cui reimpostare la quota"
            echo "Utilizzo: $0 reset-quota <username>"
            exit 1
        fi
        echo "🔄 Reimpostazione quota per utente: $2"
        docker exec web4student setquota -u "$2" 8192 10240 0 0 /
        docker exec web4student quota -u "$2" 2>/dev/null || echo "⚠️ Impossibile verificare quota"
        ;;
    
    install-adminer)
        echo "🗄️ Installazione Adminer per tutti gli utenti esistenti..."
        docker exec web4student /usr/local/bin/install_adminer.sh
        ;;
    
    remove-adminer)
        echo "🧹 Rimozione link Adminer dalle directory utenti..."
        docker exec web4student /usr/local/bin/remove_adminer_links.sh
        ;;
    
    *)
        show_usage
        exit 1
        ;;
esac
