# 🚀 Web4Student - Guida Rapida all'Avvio

## Prerequisiti
- Docker e Docker Compose installati
- Porta 8080, 2222, 8443, 3307 disponibili sul sistema host

## 🎯 Avvio Rapido

### 1. Posizionarsi nella directory del progetto
```bash
cd /ws/container/web4student
```

### 2. Avvio con script di gestione (raccomandato)
```bash
# Avvia il container
./manage.sh start

# Verifica lo stato
./manage.sh status
```

### 3. Avvio manuale con Docker Compose
```bash
# Build e avvio
docker compose up -d --build

# Verifica i container
docker compose ps
```

## 🌐 Accesso ai Servizi

Una volta avviato, i servizi saranno disponibili su:

- **🌐 Sito Web principale**: http://localhost:8080
- **🔑 SSH**: `ssh prof@localhost -p 2222` (password: `prof123`)
- **🗄️ Database MySQL**: `mysql -h localhost -P 3307 -u admin -p` (password: `admin123`)
- **👥 Directory studenti**: http://localhost:8080/~username

## 👥 Gestione Studenti

### Creazione automatica da CSV
1. Modifica il file `students.csv` con i dati degli studenti:
```csv
classe,nome,cognome,username
3A,Marco,Rossi,mrossi
3A,Giulia,Bianchi,gbianchi
```

2. Crea gli account:
```bash
./manage.sh create-users
```

### Creazione manuale
```bash
# Accedi al container
./manage.sh shell

# Crea utente manualmente
useradd -m -d /home/3A/rossi.marco -s /bin/bash mrossi
echo 'mrossi:student123' | chpasswd
mkdir -p /home/3A/rossi.marco/www
chown -R mrossi:mrossi /home/3A/rossi.marco
```

## 🛠️ Comandi Utili

### Script di gestione
```bash
./manage.sh start        # Avvia container
./manage.sh stop         # Ferma container  
./manage.sh restart      # Riavvia container
./manage.sh logs         # Visualizza log
./manage.sh shell        # Accedi alla shell
./manage.sh status       # Stato container
./manage.sh build        # Ricostruisci immagine
./manage.sh clean        # Rimuovi tutto
./manage.sh backup       # Backup home directories
./manage.sh create-users # Crea utenti da CSV
```

### Docker Compose diretto
```bash
docker compose up -d          # Avvia
docker compose down           # Ferma
docker compose logs -f        # Log in tempo reale
docker compose exec web4student bash  # Shell
```

## 📁 Struttura Directory

```
web4student/
├── Dockerfile              # Definizione immagine
├── docker-compose.yml      # Configurazione servizi
├── students.csv            # File studenti esempio
├── scripts/
│   ├── init.sh                 # Script di avvio container
│   ├── manage.sh               # Script di gestione
│   └── create_student_accounts.sh  # Script creazione utenti
└── volumes/
    ├── home/               # Home directory studenti (persistente)
    ├── mysql_data/         # Dati database (persistente) 
    ├── logs/               # Log Apache (persistente)
    └── config/             # Configurazioni personalizzate
```

## 🎓 Per gli Studenti

Ogni studente avrà:
- **Username**: come specificato nel CSV
- **Password iniziale**: `student123` (da cambiare!)
- **Home directory**: `/home/classe/cognome.nome`
- **Directory web**: `~/www/` 
- **URL web personale**: `http://localhost:8080/~username`
- **Database personale**: `db_username` (stesso user/pass dell'account)

### Primo accesso studente
```bash
# SSH
ssh username@localhost -p 2222

# Cambia password
passwd

# Naviga alla directory web
cd ~/www

# Modifica la pagina web
nano index.html
```

## 🔧 Risoluzione Problemi

### Container non si avvia
```bash
# Verifica log
./manage.sh logs

# Ricostruisci immagine
./manage.sh build

# Riavvia pulito
./manage.sh stop
./manage.sh start

# Rimozione della vecchia chiave ssh (se necessario)
ssh-keygen -f '/home/ubuntu/.ssh/known_hosts' -R '[localhost]:2222'

# In caso di problemi persistenti
# Ricostruisci il container con le nuove configurazioni
./manage.sh build

# Avvia il container
./manage.sh start

# Le directory utenti ora funzioneranno automaticamente!
# https://w4s.filippobilardo.it/~mrossi/ ✅

# Per riconfigurare alias dopo modifiche manuali
./manage.sh configure-aliases

# Per correggere permessi se necessario
./manage.sh fix-permissions
```

cd /ws/container/web4student 
docker cp volumes/config/index.html web4student:/var/www/html/index.html

### Reset completo
```bash
./manage.sh clean    # Rimuove tutto
./manage.sh start    # Riavvia da zero
```

## 📊 Monitoraggio

### Verifica servizi
```bash
# Dal host
./manage.sh status

# Dal container  
./manage.sh shell
service --status-all
```

### Test connettività
```bash
# Test web
curl http://localhost:8080

# Test SSH  
ssh prof@localhost -p 2222 -o ConnectTimeout=5

# Test MySQL
mysql -h localhost -P 3307 -u admin -p -e "SHOW DATABASES;"
```

## 💾 Backup e Ripristino

### Backup automatico
```bash
./manage.sh backup
# Crea: backup_YYYYMMDD_HHMMSS.tar.gz
```

### Ripristino
```bash
./manage.sh restore backup_20240101_120000.tar.gz
```

## 🚀 Pronto!

Il tuo ambiente Web4Student è ora configurato e pronto all'uso!

Per ulteriori dettagli consulta la documentazione completa nei file README presenti nella directory.
