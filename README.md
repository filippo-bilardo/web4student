# Container web4student
Questo container Docker è progettato per eseguire Web4Student, una distribuzione Linux minimale (solo linea di comando). Fornisce un ambiente completo con strumenti di sviluppo C/C++. E' anche fornito uno spazio per sviluppo web con Apache, PHP e MySQL/MariaDB.

## Caratteristiche principali
- la home directory è montata su un volume persistente /home
- Ambiente di sviluppo completo con compilatori (gcc, g++, make), interpreti (Python, Node.js), linguaggio Java, editor di testo (vim, nano) e strumenti di rete (curl, wget).
- Server web con Apache, PHP e MySQL/MariaDB per lo sviluppo web
- Strumenti di gestione del sistema come htop, tmux, e git
- Script di inizializzazione per configurare l'ambiente al primo avvio del container
- Documentazione dettagliata per l'installazione, la configurazione e l'uso del container
- MAPPATURA PORTE HOST:CONTAINER: "2222:22", "8080:80", "8443:443", "3307:3306"
- utente amministratore di sistema: `prof` con password iniziale `prof123`
- accesso SSH abilitato per utenti creati
- crea la homepage di base nella cartella config e nel dockerfile copia il file creato
- Commenta maggiormente dockerfile e docker compose
## Correzioni da apportare
- correggere permessi cartelle utenti e web
- aggiungere script per correggere permessi
- controllare che la creazione del db per gli utenti funzioni


## 🚀 Avvio Rapido
Per istruzioni dettagliate su come avviare e testare il container, consulta:
📖 **[README_avvio.md](README_avvio.md)** - Guida completa all'avvio e configurazione

### Avvio Base
```bash
cd /ws/container/web4student
docker compose up -d
```

### Accesso
- 🌐 **Home Page**: http://w4s.filippobilardo.it/
- 🔐 **SSH**: `ssh prof@163.192.115.36 -p 2222`
- 🗄️ **Database**: `mysql -h 163.192.115.36 -P 3307 -u username -p`


## Tecnologie incluse

### Linguaggi di Programmazione
- **C/C++**: gcc, g++, make, gdb
- **Python**: python3, pip3, virtualenv
- **Java**: OpenJDK 17, Maven, Gradle, Ant, Groovy
- **JavaScript/Node.js**: nodejs, npm, express, nodemon
- **PHP**: php-cli, php-mysql, php-mbstring

### Database
- **MySQL/MariaDB**: mysql-server, mysql-client

### Web Server
- **Apache**: con supporto SSL e rewrite
- **PHP**: integrazione completa con Apache

### Strumenti di Sviluppo
- **Git**: controllo versione
- **SSH**: accesso remoto sicuro
- **Editor**: vim, nano
- **Build Tools**: make, cmake
- **Package Managers**: apt, pip, npm, maven

### Software Educativo
- **Gnuplot**: grafici e plotting
- **Octave**: calcolo numerico (alternativa MATLAB)

### Utilità di Sistema
- **htop**: monitor processi
- **tmux**: multiplexer terminale
- **curl/wget**: download
- **net-tools**: strumenti di rete

