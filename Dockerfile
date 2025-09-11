# ===========================================================================
# Web4Student - Container Linux minimale per studenti con ambiente di sviluppo
# ===========================================================================
# Basato su Ubuntu 22.04 LTS per stabilità e supporto a lungo termine
# Include ambiente completo per programmazione C/C++, Python, Java, JavaScript, PHP
# Server web Apache con supporto PHP e database MySQL/MariaDB
# Sistema multi-utente con directory web personali per ogni studente
# ===========================================================================

FROM ubuntu:22.04

# Evita le richieste interattive durante l'installazione dei pacchetti
ENV DEBIAN_FRONTEND=noninteractive

# ===========================================================================
# INSTALLAZIONE PACCHETTI DI SISTEMA
# ===========================================================================

# Aggiorna il sistema e installa dipendenze base
RUN apt-get update && apt-get install -y \
    # ===========================================================================
    # SISTEMA BASE - Strumenti essenziali per il funzionamento del container
    # ===========================================================================
    openssh-server \
    sudo \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    tmux \
    net-tools \
    iputils-ping \
    # ===========================================================================
    # LINGUAGGI DI PROGRAMMAZIONE - C/C++
    # Compilatori e strumenti per sviluppo C/C++
    # ===========================================================================
    gcc \
    g++ \
    make \
    gdb \
    cmake \
    # ===========================================================================
    # PYTHON - Linguaggio interpretato per scripting e sviluppo
    # ===========================================================================
    python3 \
    python3-pip \
    python3-venv \
    # ===========================================================================
    # JAVA - Linguaggio compilato enterprise con ecosystem completo
    # ===========================================================================
    openjdk-17-jdk \
    maven \
    gradle \
    ant \
    groovy \
    # ===========================================================================
    # NODE.JS E JAVASCRIPT - Sviluppo web e applicazioni server-side
    # ===========================================================================
    nodejs \
    npm \
    # ===========================================================================
    # WEB SERVER E PHP - Stack per sviluppo web dinamico
    # ===========================================================================
    apache2 \
    php \
    php-cli \
    php-mysql \
    php-mbstring \
    php-xml \
    php-curl \
    libapache2-mod-php \
    # ===========================================================================
    # DATABASE MYSQL/MARIADB - Sistema di gestione database relazionale
    # ===========================================================================
    mariadb-server \
    mariadb-client \
    # ===========================================================================
    # SOFTWARE EDUCATIVO - Strumenti per matematica e analisi dati
    # ===========================================================================
    gnuplot \
    octave \
    # ===========================================================================
    # UTILITÀ AGGIUNTIVE - Strumenti di produttività e gestione file
    # ===========================================================================
    zip \
    unzip \
    tree \
    less \
    ca-certificates \
    # ===========================================================================
    # QUOTA DISCO - Strumenti per limitare lo spazio disco utenti
    # ===========================================================================
    quota \
    quotatool \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*  # Rimozione liste pacchetti per ridurre dimensione immagine

# ===========================================================================
# CONFIGURAZIONE NODE.JS - Pacchetti globali per sviluppo JavaScript
# ===========================================================================
# Installa nodemon per auto-reload durante sviluppo e express per web server
RUN npm install -g nodemon express

# ===========================================================================
# CONFIGURAZIONE SSH - Abilitazione accesso remoto sicuro
# ===========================================================================
# Crea directory per il daemon SSH
RUN mkdir /var/run/sshd

# Imposta password per root (solo per test, sconsigliato in produzione)
#RUN echo 'root:root123' | chpasswd
# Configura SSH per permettere login root (solo per ambiente educativo)
#RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Assicura che SSH sia sulla porta standard 22 (mappata a 2222 dall'host)
RUN sed -i 's/Port 22/Port 22/' /etc/ssh/sshd_config

# ===========================================================================
# CREAZIONE UTENTE AMMINISTRATORE - Account 'prof' per gestione sistema
# ===========================================================================
# Crea l'utente prof con privilegi sudo per amministrazione del sistema
RUN useradd -m -s /bin/bash -G sudo prof

# Imposta password iniziale per l'utente prof (da cambiare al primo accesso)
RUN echo 'prof:prof123' | chpasswd

# Assicura che la home directory esista con i permessi corretti
RUN mkdir -p /home/prof && chown prof:prof /home/prof && chmod 755 /home/prof

# Crea directory www per il professore
RUN mkdir -p /home/prof/www && chown prof:prof /home/prof/www && chmod 755 /home/prof/www

# ===========================================================================
# CONFIGURAZIONE APACHE - Abilitazione moduli per funzionalità web avanzate
# ===========================================================================
# Abilita mod_rewrite per URL rewriting (necessario per molte applicazioni web)
RUN a2enmod rewrite

# Abilita mod_userdir per directory personali utenti (/~username)
RUN a2enmod userdir

# Abilita mod_ssl per supporto HTTPS
RUN a2enmod ssl

# Abilita modulo PHP per Apache
RUN a2enmod php8.1

# ===========================================================================
# CONFIGURAZIONE DIRECTORY UTENTI APACHE - Setup per siti web personali
# ===========================================================================
# Configura Apache per servire file dalla directory 'www' di ogni utente
# Gli studenti potranno accedere ai loro siti su http://server/~username

# Crea la configurazione corretta per userdir sostituendo il file predefinito
RUN cat > /etc/apache2/mods-available/userdir.conf << 'EOF'
<IfModule mod_userdir.c>
    UserDir www
    UserDir disabled root

    <Directory /home/*/www>
        AllowOverride All
        Options Indexes FollowSymLinks MultiViews
        Require all granted
    </Directory>
</IfModule>
EOF

# ===========================================================================
# CONFIGURAZIONE MYSQL/MARIADB - Setup database con utenti amministrativi
# ===========================================================================

# Configura MySQL per accettare connessioni esterne (cambia bind-address)
# Necessario per connessioni dall'host tramite porta mappata
RUN sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Inizializza il database MySQL durante il build del container
# Questo evita problemi di permessi quando il container viene avviato
RUN mysql_install_db --user=mysql --datadir=/var/lib/mysql

# Configura gli utenti MySQL durante il build
# Avvia temporaneamente MySQL per configurazione iniziale
RUN service mariadb start && \
    sleep 5 && \
    mysql -u root -e "CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin123';" && \
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;" && \
    mysql -u root -e "CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'admin123';" && \
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;" && \
    mysql -u root -e "FLUSH PRIVILEGES;" && \
    service mariadb stop

# Assicura che la directory MySQL abbia i permessi corretti
RUN chown -R mysql:mysql /var/lib/mysql

# ===========================================================================
# CONFIGURAZIONE QUOTE DISCO - Limitazione spazio utenti
# ===========================================================================
# Crea i file di database delle quote
RUN touch /quota.user /quota.group
RUN chmod 600 /quota.user /quota.group

# Configura il supporto quote nel sistema
# Nota: Le quote funzionano pienamente solo se il filesystem supporta le quote
# In ambiente Docker, le quote sono simulate per scopi educativi
RUN echo "# Quota configuration" >> /etc/fstab
RUN quotacheck -cum / 2>/dev/null || true
RUN quotaon / 2>/dev/null || true

# ===========================================================================
# CREAZIONE DIRECTORY E VOLUMI - Setup per persistenza dati
# ===========================================================================
# Crea directory per file condivisi tra studenti
RUN mkdir -p /home/shared

# Crea directory principale per il web server
RUN mkdir -p /var/www/html

# ===========================================================================
# COPIA SCRIPT E CONFIGURAZIONI - File necessari per il funzionamento
# SCRIPT DI AVVIO - Inizializzazione del container
# ===========================================================================
# Copia gli script di gestione nella directory bin del sistema
# Copia e rende eseguibile lo script di inizializzazione
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh
# ===========================================================================

# ===========================================================================
# HOMEPAGE WEB - Pagina principale del sito
# ===========================================================================
# Copia la homepage personalizzata dal file di configurazione
# invece di generarla con comandi echo
COPY volumes/config/index.html /var/www/html/index.html

# ===========================================================================
# ADMINER - Tool di gestione database web-based
# ===========================================================================
# Copia Adminer nella directory web principale di Apache
COPY volumes/config/adminer.php /var/www/html/adminer.php

# ===========================================================================
# ESPOSIZIONE PORTE - Servizi accessibili dall'esterno
# ===========================================================================
# Le porte esposte dal container (mappate dall'host tramite docker-compose):
# - 22: SSH (mappata su 2222 dell'host)
# - 80: HTTP Apache (mappata su 8080 dell'host)  
# - 443: HTTPS Apache (mappata su 8443 dell'host)
# - 3000: Node.js applications (mappata su 3000 dell'host)
# - 3306: MySQL/MariaDB (mappata su 3307 dell'host)
EXPOSE 22 80 443 3000 3306

# ===========================================================================
# COMANDO PREDEFINITO - Avvia tutti i servizi
# ===========================================================================
# Lo script init.sh si occupa di:
# - Avviare MySQL/MariaDB
# - Avviare SSH daemon  
# - Avviare Apache
# - Creare utenti da CSV se presente
# - Mantenere il container in esecuzione
CMD ["/usr/local/bin/init.sh"]
