# 📋 Web4Student - Checklist Operativo

**Guida passo-passo per setup, esecuzione, verifica e manutenzione del container educativo**

[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Status](https://img.shields.io/badge/Status-Ready-green.svg)]()

---

## 🎯 Panoramica Checklist

Questa checklist ti guida attraverso **4 fasi principali**:
1. **🏗️ SETUP** - Creazione e configurazione iniziale
2. **🚀 ESECUZIONE** - Avvio e gestione del container
3. **✅ VERIFICA** - Test di tutte le funzionalità
4. **🔧 MANUTENZIONE** - Risoluzione problemi e aggiornamenti

**Tempo stimato**: 15-30 minuti per setup completo

---

## 🏗️ FASE 1: SETUP E CONFIGURAZIONE

### ✅ 1.1 Prerequisiti Sistema
- [ ] **Docker installato e funzionante**
  ```bash
  docker --version          # ≥ 20.10
  docker compose version    # ≥ 2.0
  ```
- [ ] **Porte libere sul sistema**
  ```bash
  netstat -tlnp | grep -E ':(80|443|22|3306|8080|8443|2222|3307)'
  # Non dovrebbero esserci processi in ascolto
  ```
- [ ] **Spazio disco sufficiente** (≥ 5GB liberi)
- [ ] **Permessi Docker** (utente nel gruppo docker)

### ✅ 1.2 Download e Preparazione
- [ ] **Clona repository**
  ```bash
  git clone https://github.com/filippo-bilardo/web4student.git
  cd web4student
  ```
- [ ] **Verifica struttura file**
  ```bash
  ls -la
  # Dovresti vedere: Dockerfile, docker-compose.yml, manage.sh, README.md
  ```
- [ ] **Rendi eseguibili gli script**
  ```bash
  chmod +x manage.sh
  chmod +x scripts/*.sh
  ```

### ✅ 1.3 Configurazione Iniziale
- [ ] **Verifica configurazione Docker**
  ```bash
  cat docker-compose.yml
  # Controlla porte, volumi, variabili d'ambiente
  ```
- [ ] **Prepara file studenti (opzionale)**
  ```bash
  # Crea students.csv se necessario
  cat > volumes/students.csv << EOF
  classe,cognome,nome,username
  3A,Rossi,Marco,rossi.marco
  3A,Bianchi,Giulia,bianchi.giulia
  EOF
  ```
- [ ] **Verifica permessi directory**
  ```bash
  ls -ld volumes/
  # drwxrwxr-x dovrebbe essere il permesso
  ```

---

## 🚀 FASE 2: AVVIO E GESTIONE

### ✅ 2.1 Primo Avvio
- [ ] **Build del container**
  ```bash
  ./manage.sh build
  # Oppure: docker compose build
  ```
- [ ] **Avvio container**
  ```bash
  ./manage.sh start
  # Oppure: docker compose up -d
  ```
- [ ] **Verifica stato**
  ```bash
  ./manage.sh status
  # Dovrebbe mostrare: web4student (running)
  ```

### ✅ 2.2 Creazione Account Studenti aggiuntivi (Opzionale)
- [ ] **Esegui script creazione utenti**
  modifica il file students.csv in `volumes/`
  ```bash
  ./manage.sh create-users
  # Oppure: ./scripts/create_student_accounts.sh volumes/students.csv
  ```
- [ ] **Verifica creazione database**
  ```bash
  docker exec web4student mysql -u root -e "SHOW DATABASES;"
  # Dovresti vedere: db_username per ogni studente
  ```

### ✅ 2.3 Configurazione Sicurezza
- [ ] **Cambia password amministratore**
  ```bash
  ssh prof@localhost -p 2222
  passwd  # Cambia la password definita dall'amministratore
  exit
  ```

---

## ✅ FASE 3: VERIFICA FUNZIONALITÀ

### ✅ 3.1 Test Accesso Web
- [ ] **Homepage principale**
  ```bash
  curl -I http://localhost:8080
  # HTTP/1.1 200 OK
  ```
- [ ] **Accesso browser**
  ```bash
  # Apri: http://localhost:8080
  # Dovresti vedere la homepage di Web4Student
  ```
- [ ] **Test HTTPS (se configurato)**
  ```bash
  curl -I https://localhost:8443
  ```

### ✅ 3.2 Test Accesso SSH
- [ ] **Connessione amministratore**
  ```bash
  ssh prof@localhost -p 2222
  # Password: quella definita in .env (o quella cambiata)
  whoami  # Dovrebbe mostrare: prof
  exit
  ```
- [ ] **Connessione studente (se creato)**
  ```bash
  ssh rossi.marco@localhost -p 2222
  # Password: valore configurato in STUDENT_DEFAULT_PASSWORD
  pwd  # Dovrebbe mostrare: /home/3A/Rossi.Marco
  passwd  # Cambia la password al primo accesso
  exit
  ```

### ✅ 3.3 Test Database
- [ ] **Connessione MySQL esterna**
  ```bash
  #mysql -h localhost -P 3307 -u admin -p
  mysql -h 172.22.0.9 -P 3306 -u admin -p
  # Password: valore configurato in MYSQL_ADMIN_PASSWORD
  SHOW DATABASES;
  # Dovresti vedere: web4student, db_username, etc.
  exit
  ```
- [ ] **Test Adminer**
  ```bash
  # Browser: http://localhost:8080/adminer.php
  # Server: localhost:3307
  # Username: MYSQL_ADMIN_USER, Password: MYSQL_ADMIN_PASSWORD
  ```

### ✅ 3.4 Test Siti Web Studenti
- [ ] **Sito studente (se creato)**
  ```bash
  curl http://localhost:8080/~rossi.marco/
  # Dovrebbe mostrare la pagina personale
  ```
- [ ] **Adminer personale**
  ```bash
  # Browser: http://localhost:8080/~rossi.marco/adminer.php
  # Server: localhost, Username: rossi.marco, Password: rossi.marco123
  ```

### ✅ 3.5 Test Funzionalità Sviluppo
- [ ] **Accesso shell e comandi**
  ```bash
  ssh prof@localhost -p 2222
  exit
  ```

---

## 🔧 FASE 4: MANUTENZIONE E RISOLUZIONE PROBLEMI

### ✅ 4.1 Monitoraggio Routine
- [ ] **Stato container giornaliero**
  ```bash
  ./manage.sh status
  docker stats web4student
  ```
- [ ] **Log di sistema**
  ```bash
  ./manage.sh logs
  # Controlla errori o warning
  ```
- [ ] **Utilizzo risorse**
  ```bash
  docker exec web4student df -h     # Spazio disco
  docker exec web4student free -h   # RAM
  ./manage.sh student-usage         # Home studenti piu' pesanti
  ```

### ✅ 4.2 Backup Dati
- [ ] **Backup completo**
  ```bash
  ./manage.sh backup
  # Crea: backup_YYYYMMDD_HHMMSS.tar.gz
  ```
- [ ] **Verifica backup**
  ```bash
  ls -la backup_*.tar.gz
  tar -tzf backup_*.tar.gz | head -10
  ```

### ✅ 4.3 Risoluzione Problemi Comuni

#### 🔴 Container non si avvia
- [ ] **Verifica porte occupate**
  ```bash
  netstat -tlnp | grep -E ':(80|443|22|3306|8080|8443|2222|3000|3030|3307)'
  # Se occupate, cambia porte in docker-compose.yml
  ```
- [ ] **Log di avvio**
  ```bash
  ./manage.sh logs
  docker logs web4student
  ```
- [ ] **Ricostruzione**
  ```bash
  ./manage.sh clean
  ./manage.sh build
  ./manage.sh start
  ```

#### 🔴 Accesso SSH fallisce
- [ ] **Pulizia chiavi SSH**
  ```bash
  ssh-keygen -f "~/.ssh/known_hosts" -R "[localhost]:2222"
  ```
- [ ] **Test connessione verbosa**
  ```bash
  ssh -v prof@localhost -p 2222
  ```
- [ ] **Verifica servizio SSH nel container**
  ```bash
  docker exec web4student service ssh status
  ```

#### 🔴 Database non accessibile
- [ ] **Stato servizio MySQL**
  ```bash
  docker exec web4student service mysql status
  docker exec web4student service mysql start
  ```
- [ ] **Test connessione locale**
  ```bash
  docker exec -it web4student mysql -u root -p
  # Password: valore configurato in MYSQL_ADMIN_PASSWORD
  ```
- [ ] **Verifica porte**
  ```bash
  docker exec web4student netstat -tlnp | grep 3306
  ```

#### 🔴 Sito web non funziona
- [ ] **Stato Apache**
  ```bash
  docker exec web4student service apache2 status
  docker exec web4student service apache2 start
  ```
- [ ] **Log Apache**
  ```bash
  docker exec web4student tail -f /var/log/apache2/error.log
  ```
- [ ] **Test locale**
  ```bash
  docker exec web4student curl http://localhost/
  ```

#### 🔴 Problemi permessi
- [ ] **Correzione permessi**
  ```bash
  ./scripts/test_security.sh
  # Se fallisce, ricrea utenti
  ./manage.sh create-users
  ```
- [ ] **Verifica ownership**
  ```bash
  docker exec web4student ls -la /home/
  ```

### ✅ 4.4 Aggiornamenti e Manutenzione
- [ ] **Aggiornamento container**
  ```bash
  ./manage.sh stop
  docker pull ubuntu:22.04
  ./manage.sh build
  ./manage.sh start
  ```
- [ ] **Pulizia Docker**
  ```bash
  docker system prune -a  # Rimuovi immagini non usate
  docker volume prune     # Rimuovi volumi orfani
  ```
- [ ] **Rotazione log**
  ```bash
  docker exec web4student logrotate -f /etc/logrotate.conf
  ```

---

## 📊 RIEPILOGO FINALE

### ✅ Checklist Completamento
- [ ] **Setup completato** (Fase 1)
- [ ] **Container avviato** (Fase 2)
- [ ] **Funzionalità verificate** (Fase 3)
- [ ] **Sistema stabile** (Fase 4)

### 🎯 Metriche di Successo
- [ ] Container in esecuzione: `docker ps`
- [ ] Accesso SSH funzionante
- [ ] Sito web accessibile
- [ ] Database operativo
- [ ] Studenti possono accedere
- [ ] Backup funzionante

### 📞 Supporto
Se incontri problemi:
1. **Controlla i log**: `./manage.sh logs`
2. **Verifica porte**: `netstat -tlnp`
3. **Test componenti**: Segui Fase 3
4. **Apri issue**: [GitHub Issues](https://github.com/filippo-bilardo/web4student/issues)

---

**🎉 Setup completato! Il tuo ambiente Web4Student è pronto per l'uso educativo!**
