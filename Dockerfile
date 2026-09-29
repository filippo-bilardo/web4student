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
    quota \
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
    # Installazione di Node.js LTS tramite NodeSource repository
    # ===========================================================================
    ca-certificates \
    gnupg \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*  # Rimozione liste pacchetti per ridurre dimensione immagine

# ===========================================================================
# INSTALLAZIONE NODE.JS LTS - Versione 24.x (LTS)
# ===========================================================================
# Usa NodeSource repository per avere l'ultima versione LTS di Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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

# Mantiene l'account root bloccato per l'accesso SSH.
#RUN passwd -l root
# Configura SSH per permettere login root (solo per ambiente educativo)
#RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Assicura che SSH sia sulla porta standard 22 (mappata a 2222 dall'host)
RUN sed -i 's/Port 22/Port 22/' /etc/ssh/sshd_config

# ===========================================================================
# CREAZIONE UTENTI AMMINISTRATORI - Account persistenti per gestione sistema
# ===========================================================================
RUN useradd -m -s /bin/bash -G sudo prof \
    && useradd -m -s /bin/bash -G sudo fb \
    && mkdir -p /home/prof/www /home/fb/www \
    && chown -R prof:prof /home/prof \
    && chown -R fb:fb /home/fb \
    && chmod 755 /home/prof /home/prof/www /home/fb /home/fb/www

RUN printf '%s\n' \
    'prof ALL=(ALL) ALL' \
    'fb ALL=(ALL) ALL' \
    > /etc/sudoers.d/web4student-admins \
    && chmod 440 /etc/sudoers.d/web4student-admins

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
RUN echo '<IfModule mod_userdir.c>' > /etc/apache2/mods-available/userdir.conf && \
     echo '    UserDir www' >> /etc/apache2/mods-available/userdir.conf && \
     echo '    UserDir disabled root' >> /etc/apache2/mods-available/userdir.conf && \
     echo '' >> /etc/apache2/mods-available/userdir.conf && \
     echo '    <Directory /home/*/www>' >> /etc/apache2/mods-available/userdir.conf && \
     echo '        AllowOverride All' >> /etc/apache2/mods-available/userdir.conf && \
     echo '        Options Indexes FollowSymLinks MultiViews' >> /etc/apache2/mods-available/userdir.conf && \
     echo '        Require all granted' >> /etc/apache2/mods-available/userdir.conf && \
     echo '    </Directory>' >> /etc/apache2/mods-available/userdir.conf && \
     echo '' >> /etc/apache2/mods-available/userdir.conf && \
     echo '    <Directory /home/*/*/www>' >> /etc/apache2/mods-available/userdir.conf && \
     echo '        AllowOverride All' >> /etc/apache2/mods-available/userdir.conf && \
     echo '        Options Indexes FollowSymLinks MultiViews' >> /etc/apache2/mods-available/userdir.conf && \
    echo '        Require all granted' >> /etc/apache2/mods-available/userdir.conf && \
    echo '    </Directory>' >> /etc/apache2/mods-available/userdir.conf && \
    echo '</IfModule>' >> /etc/apache2/mods-available/userdir.conf

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
# CREAZIONE DIRECTORY E VOLUMI - Setup per persistenza dati
# ===========================================================================
# Crea directory per file condivisi tra studenti
RUN mkdir -p /home/shared

# Crea directory principale per il web server
RUN mkdir -p /var/www/html /usr/local/share/web4student/webroot

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
COPY volumes/config/index.html /usr/local/share/web4student/webroot/index.html
COPY volumes/config/favicon.svg /var/www/html/favicon.svg
COPY volumes/config/favicon.svg /usr/local/share/web4student/webroot/favicon.svg

# ===========================================================================
# ADMINER - Tool di gestione database web-based
# ===========================================================================
# Copia Adminer nella directory web principale di Apache
COPY volumes/config/adminer.php /var/www/html/adminer.php
COPY volumes/config/adminer.php /usr/local/share/web4student/webroot/adminer.php

# ===========================================================================
# INFRASTRUTTURA - Documentazione tecnica del sistema
# ===========================================================================
# Copia la documentazione dell'infrastruttura nella directory web
COPY volumes/config/infrastruttura.html /var/www/html/infrastruttura.html
COPY volumes/config/infrastruttura.html /usr/local/share/web4student/webroot/infrastruttura.html
COPY volumes/config/4c.php /var/www/html/4c.php
COPY volumes/config/4c.php /usr/local/share/web4student/webroot/4c.php

# Limite processi per gli account studenti (protezione anti-fork-bomb)
COPY volumes/config/web4student-students.conf /etc/security/limits.d/web4student-students.conf

# ===========================================================================
# ESPOSIZIONE PORTE - Servizi accessibili dall'esterno
# ===========================================================================
# Le porte esposte dal container (mappate dall'host tramite docker-compose):
# - 22: SSH (mappata su 2222 dell'host)
# - 80: HTTP Apache (mappata su 8080 dell'host)  
# - 443: HTTPS Apache (mappata su 8443 dell'host)
# - 3000: Node.js applications (mappata su 3001 dell'host)
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
