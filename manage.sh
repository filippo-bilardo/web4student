#!/bin/bash

# ==============================================================================
# Script di Gestione Web4Student
# ==============================================================================
# Descrizione: Fornisce un'interfaccia a riga di comando per gestire il ciclo di
#              vita dell'ambiente Docker, degli utenti (studenti) e del database
#              MySQL per la piattaforma Web4Student.
# 
# Versione: 1.1 - 29/06/26 - Filippo Bilardo
# ==============================================================================

# Mostra la guida all'uso dello script e l'elenco di tutti i comandi disponibili.
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
    echo "  create-users-file - Crea utenti da un file CSV diverso"
    echo "  restore-users     - Ripristina account Linux dalle home persistenti"
    echo "  configure-aliases - Riconfigura alias Apache per utenti esistenti"
    echo "  configure-quotas  - Applica le quote disco amministrative"
    echo "  configure-limits  - Applica il limite processi agli studenti"
    echo "  check             - Esegue i controlli di integrità del progetto"
    echo "  student-usage     - Mostra lo spazio occupato dalle home degli studenti"
    echo "  system-usage      - Mostra studenti loggati e utilizzo CPU/RAM"
    echo "  mysql-status      - Verifica stato MySQL/MariaDB"
    echo "  mysql-fix         - Corregge problemi MySQL"
    echo "  mysql-root        - Accede a MySQL come root"
    echo "  mysql-admin       - Accede a MySQL come admin"
    echo "  clean             - Rimuove container e immagini"
    echo "  backup            - Crea backup delle home directory"
    echo "  restore           - Ripristina backup delle home directory"
    echo ""
    echo "Esempi:"
    echo "  $0 start"
    echo "  $0 create-users"
    echo "  $0 restore-users"
    echo "  $0 configure-aliases"
    echo "  $0 student-usage"
    echo "  $0 install-adminer"
    echo "  $0 shell"
}

create_users_from_csv() {
    local csv_file="$1"
    local container_csv

    if [ ! -f "$csv_file" ]; then
        echo "❌ File CSV non trovato: $csv_file"
        return 1
    fi

    case "$csv_file" in
        volumes/students/*)
            container_csv="/home/students/${csv_file#volumes/students/}"
            ;;
        /ws/container/web4student/volumes/students/*)
            container_csv="/home/students/${csv_file#/ws/container/web4student/volumes/students/}"
            ;;
        volumes/students.csv)
            container_csv="/home/students.csv"
            ;;
        /ws/container/web4student/volumes/students.csv)
            container_csv="/home/students.csv"
            ;;
        *)
            echo "❌ Il file deve trovarsi in volumes/students/ oppure essere volumes/students.csv"
            return 1
            ;;
    esac

    echo "👥 Creazione utenti dal file $csv_file..."
    docker compose exec web4student /usr/local/bin/create_student_accounts.sh "$container_csv"
    echo "🔧 Configurazione alias Apache..."
    docker compose exec web4student /usr/local/bin/configure_user_aliases.sh
    docker compose exec web4student /usr/local/bin/configure_disk_quotas.sh
    docker compose exec web4student /usr/local/bin/configure_student_limits.sh
    docker compose exec web4student /usr/local/bin/manage_auth_state.sh export
    echo "✅ Utenti creati e configurati dal file $csv_file!"
}

# Gestione dei vari comandi passati come primo argomento
case "$1" in
    # Avvia i container Docker definiti in docker-compose.yml in modalità detached (-d)
    # e mostra le informazioni principali per le connessioni Web, SSH e MySQL
    start)
        echo "🚀 Avvio Web4Student..."
        docker compose up -d
        echo "✅ Container avviato!"
        echo "🌐 Web: http://w4s.filippobilardo.it"
        echo "🔑 SSH: ssh prof@filippobilardo.it -p 2222"
        echo "🗄️ MySQL: mysql -h localhost -P 3307 -u admin -p"
        ;;
    
    # Ferma e rimuove i container Docker attivi mantenendo intatti i volumi persistenti
    stop)
        echo "⏹️  Arresto Web4Student..."
        docker compose down
        echo "✅ Container arrestato!"
        ;;
    
    # Esegue il riavvio rapido di tutti i container Docker configurati
    restart)
        echo "🔄 Riavvio Web4Student..."
        docker compose restart
        echo "✅ Container riavviato!"
        ;;
    
    # Ricostruisce le immagini Docker dei container senza utilizzare la cache (pulizia build)
    build)
        echo "🔨 Ricostruzione immagine Web4Student..."
        docker compose build --no-cache
        echo "✅ Immagine ricostruita!"
        ;;
    
    # Mostra e segue in tempo reale (live log stream) i log del container principale 'web4student'
    logs)
        echo "📋 Log del container Web4Student:"
        docker compose logs -f web4student
        ;;
    
    # Consente di entrare direttamente in sessione interattiva Bash dentro al container principale
    shell)
        echo "🐚 Accesso alla shell del container..."
        docker compose exec web4student /bin/bash
        ;;
    
    # Mostra lo stato di esecuzione dei container e verifica quali servizi di sistema
    # (Apache, MariaDB, SSH, ecc.) sono effettivamente in esecuzione all'interno del container
    status)
        echo "📊 Status dei container:"
        docker compose ps
        echo ""
        echo "📊 Status dei servizi nel container:"
        docker compose exec web4student service --status-all 2>/dev/null || echo "Container non in esecuzione"
        ;;
    
    # Gestisce la creazione iniziale degli account studente a partire dal file CSV:
    # 1. Verifica che students.csv esista nella cartella volumi locali.
    # 2. Crea gli utenti Linux, le home directory e configura le relative password.
    # 3. Imposta gli alias Apache per rendere navigabili i siti degli studenti.
    # 4. Esporta lo stato di autenticazione per consentirne il ripristino futuro.
    create-users)
        create_users_from_csv volumes/students.csv
        ;;

    # Crea account studenti usando un file CSV alternativo montato in /home.
    # Esempio: ./manage.sh create-users-file volumes/students/2026_5Fi.csv
    create-users-file)
        if [ -z "$2" ]; then
            echo "❌ Specifica il file CSV da utilizzare"
            echo "Utilizzo: $0 create-users-file <file.csv>"
            exit 1
        fi
        create_users_from_csv "$2"
        ;;

    # Ripristina gli account di sistema Linux a partire dalle home directory esistenti
    # ed importa lo stato dell'autenticazione precedentemente salvato.
    # Utile se si ricostruisce il container mantenendo i dati utente persistenti.
    restore-users)
        echo "♻️  Ripristino account Linux dalle home persistenti..."
        docker compose exec web4student /usr/local/bin/manage_auth_state.sh restore
        docker compose exec web4student /usr/local/bin/restore_persisted_accounts.sh
        docker compose exec web4student /usr/local/bin/configure_user_aliases.sh
        docker compose exec web4student /usr/local/bin/configure_disk_quotas.sh
        docker compose exec web4student /usr/local/bin/configure_student_limits.sh
        docker compose exec web4student /usr/local/bin/manage_auth_state.sh export
        echo "✅ Account ripristinati!"
        ;;

    # Ricrea o riconfigura i file di alias web Apache per ciascun utente studente presente nel sistema.
    configure-aliases)
        echo "🔧 Riconfigurazione alias Apache per utenti esistenti..."
        docker compose exec web4student /usr/local/bin/configure_user_aliases.sh
        echo "✅ Alias riconfigurati!"
        ;; 

    configure-quotas)
        docker compose exec web4student /usr/local/bin/configure_disk_quotas.sh
        ;;

    configure-limits)
        docker compose exec web4student /usr/local/bin/configure_student_limits.sh
        ;;

    check)
        ./scripts/check_project.sh
        ;;

    # Esegue lo script locale per analizzare ed evidenziare l'uso dello spazio su disco di ciascuna home utente
    student-usage)
        echo "📦 Riepilogo spazio occupato dalle home degli studenti..."
        ./scripts/student_usage_summary.sh
        ;;

    # Mostra le sessioni degli studenti e le risorse utilizzate dal container.
    system-usage)
        docker compose exec web4student /usr/local/bin/system_usage.sh
        ;;
    
    # Controlla lo stato di MySQL/MariaDB all'interno del container tramite script dedicato
    mysql-status)
        echo "🔍 Verifica stato MySQL/MariaDB..."
        docker compose exec web4student /usr/local/bin/mysql_status.sh
        ;;
    
    # Tenta di risolvere e riparare i problemi comuni di avvio o configurazione di MySQL:
    # - Reimposta i permessi corretti della directory dati (/var/lib/mysql).
    # - Inizializza il DB di sistema se assente.
    # - Riavvia il demone del database.
    # - Crea e garantisce tutti i privilegi per l'utente 'admin'.
    mysql-fix)
        echo "🔧 Correzione problemi MySQL..."
        docker compose exec web4student bash -c "
            # Corregge i permessi sul volume dei dati MySQL
            chown -R mysql:mysql /var/lib/mysql
            # Se il database non è mai stato inizializzato, esegue l'installazione iniziale dei DB di sistema
            if [ ! -d '/var/lib/mysql/mysql' ]; then
                mysql_install_db --user=mysql --datadir=/var/lib/mysql
            fi
            # Riavvia il servizio MariaDB
            service mariadb restart
            # Attende l'avvio completo del servizio
            sleep 3
            # Ripristina l'utente 'admin' per l'accesso amministrativo esterno
            mysql -u root -e "CREATE USER IF NOT EXISTS '\$MYSQL_ADMIN_USER'@'%' IDENTIFIED BY '\$MYSQL_ADMIN_PASSWORD';"
            mysql -u root -e "ALTER USER '\$MYSQL_ADMIN_USER'@'%' IDENTIFIED BY '\$MYSQL_ADMIN_PASSWORD';"
            mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '\$MYSQL_ADMIN_USER'@'%' WITH GRANT OPTION;"
            mysql -u root -e 'FLUSH PRIVILEGES;'
        "
        echo "✅ MySQL corretto!"
        ;;
    
    # Apre una console MySQL interattiva all'interno del container autenticandosi come 'root'
    mysql-root)
        echo "🗄️ Accesso MySQL come root..."
        docker compose exec web4student mysql -u root
        ;;
    
    # Apre una console MySQL interattiva all'interno del container autenticandosi come 'admin' (richiede password)
    mysql-admin)
        echo "🗄️ Accesso MySQL come admin..."
        docker compose exec web4student sh -lc 'MYSQL_PWD="$MYSQL_ADMIN_PASSWORD" mysql -u "$MYSQL_ADMIN_USER"'
        ;;
    
    # Rimuove tutti i container, le immagini buildate, i volumi e i container orfani dell'ambiente.
    # Richiede conferma interattiva da parte dell'utente per sicurezza.
    clean)
        echo "🧹 Pulizia completa..."
        read -p "⚠️  Sei sicuro? Questo rimuoverà tutti i container e le immagini. (y/N): " -n 1 -r
        echo
        # Verifica la conferma dell'utente
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose down --rmi all --volumes --remove-orphans
            echo "✅ Pulizia completata!"
        else
            echo "❌ Operazione annullata."
        fi
        ;;
    
    # Crea un archivio compresso tar.gz contenente tutte le home directory (/volumes/home) degli studenti,
    # inserendo un timestamp nel nome del file risultante per l'archiviazione
    backup)
        echo "💾 Backup delle home directory..."
        # Genera il nome della cartella temporanea basata sulla data corrente
        BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        # Copia ricorsivamente il contenuto delle home dei ragazzi
        cp -r volumes/home/* "$BACKUP_DIR/" 2>/dev/null || true
        # Crea il pacchetto compresso tar.gz
        tar -czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
        # Elimina la cartella temporanea non compressa
        rm -rf "$BACKUP_DIR"
        echo "✅ Backup creato: ${BACKUP_DIR}.tar.gz"
        ;;
    
    # Ripristina i dati degli studenti estraendo un file di backup .tar.gz specificato
    # all'interno della directory dei volumi delle home
    restore)
        # Verifica se è stato passato il file di backup come secondo argomento
        if [ -z "$2" ]; then
            echo "❌ Specifica il file di backup da ripristinare"
            echo "Utilizzo: $0 restore <backup.tar.gz>"
            exit 1
        fi
        echo "📥 Ripristino backup: $2..."
        # Estrae l'archivio specificato
        tar -xzf "$2"
        # Rileva il nome della cartella generata rimuovendo .tar.gz
        BACKUP_DIR=$(basename "$2" .tar.gz)
        # Ripristina i file copiandoli nel volume home condiviso
        cp -r "$BACKUP_DIR"/* volumes/home/
        # Pulisce la directory temporanea estratta
        rm -rf "$BACKUP_DIR"
        echo "✅ Backup ripristinato!"
        ;;
        
    # Comando di fallback: se viene inserito un parametro non riconosciuto o nessun parametro,
    # viene mostrato l'uso corretto e lo script termina con codice d'errore
    *)
        show_usage
        exit 1
        ;;
esac
