# Analisi IaC: Dockerfile e Docker Compose

## Ambito e stato attuale

Il repository definisce l'infrastruttura applicativa attraverso `Dockerfile` e
`docker-compose.yml`. Non sono presenti configurazioni Terraform, OpenTofu,
Ansible o di un altro provider IaC: Docker Compose e gli script shell sono
quindi l'unica fonte di verita' dell'ambiente.

L'approccio e' adeguato a un laboratorio locale, ma il container riunisce web
server, SSH, database e ambienti di sviluppo per tutti gli studenti. In un
contesto raggiungibile dalla rete, una compromissione di un servizio o di un
account puo' coinvolgere l'intero ambiente didattico.

## Criticita' prioritarie

| Priorita' | Evidenza | Impatto | Miglioramento proposto |
|---|---|---|---|
| Critica | `Dockerfile` e `docker-compose.yml` contengono password note (`prof123`, `fb123`, `admin123`, `root123`) e `scripts/init.sh` ricrea gli account con le stesse credenziali. | Accesso non autorizzato a SSH e database; la rotazione tramite variabili d'ambiente non e' effettiva. | Eliminare le credenziali dal repository e usare Docker secrets o file `.env` locali non versionati. Generare o richiedere le password al primo avvio, memorizzandone solo gli hash dove applicabile. |
| Critica | MariaDB ascolta su `0.0.0.0`, la porta `3307` e' pubblicata sull'host e l'utente `admin`@`%` riceve `ALL PRIVILEGES ... WITH GRANT OPTION`. | Un account amministrativo con password nota e' raggiungibile da ogni rete consentita dall'host. | Non pubblicare MariaDB; limitarlo alla rete Docker. Se l'accesso esterno e' indispensabile, consentire IP specifici, usare un account senza `GRANT OPTION`, password segrete e TLS. |
| Critica | Il servizio riceve la capability `SYS_ADMIN`. Gli utenti amministrativi nel container hanno `sudo` e SSH e' esposto. | `SYS_ADMIN` amplia in modo significativo la superficie di escape dal container, specialmente se un account privilegiato viene compromesso. | Rimuovere `SYS_ADMIN` e verificare la funzionalita' delle quote con una soluzione compatibile con il filesystem host. Applicare `cap_drop: [ALL]` e aggiungere solo le capability strettamente indispensabili. |
| Alta | Sono pubblicate su tutte le interfacce host SSH, HTTP, Node.js, MariaDB, tre porte di esercizio e l'intervallo `2226-2999`. I commenti indicano invece che i servizi sarebbero interni. | Superficie di rete molto piu' ampia del necessario e comportamento difforme dalla documentazione. | Esporre solo SSH e il reverse proxy necessario. Per i servizi locali usare binding `127.0.0.1:HOST:CONTAINER`; mantenere le porte di esercizio in una rete dedicata o abilitarle con un override Compose esplicito. |
| Alta | Il Dockerfile usa `FROM ubuntu:22.04`, pacchetti APT non versionati, `curl ... | bash` per NodeSource e `npm install -g` non bloccato. | Build non riproducibili; una build futura puo' introdurre versioni inattese o dipendere da uno script remoto modificato. | Fissare l'immagine base a un digest, definire versioni compatibili per i pacchetti critici e verificare firma/checksum della fonte Node. Usare un lockfile o versioni esatte per i pacchetti npm globali. |
| Alta | Non esiste `.dockerignore`; le esclusioni di `.gitignore` non si applicano al contesto di build Docker. | Le home, i dati MariaDB, CSV riservati e backup possono essere inviati al daemon Docker durante `docker build`, rallentando la build ed esponendo dati al daemon o a cache di build. | Aggiungere `.dockerignore` che escluda almeno `.git`, `volumes/home`, `volumes/mysql_data`, CSV studenti, log, backup, file `.env` e artefatti temporanei. |
| Alta | I volumi dati sono bind mount relativi (`./volumes/...`) con permessi modificati nel container. | Dipendenza da UID/GID, filesystem e layout dell'host; il deployment non e' portabile e un errore di permessi puo' rendere indisponibili dati persistenti. | Parametrizzare i percorsi con variabili, documentare proprietario e backup, e preferire named volume dove non sia richiesto il browsing diretto dell'host. Conservare l'attuale bind mount delle home solo se e' un requisito didattico esplicito. |

## Miglioramenti importanti

| Area | Osservazione | Miglioramento |
|---|---|---|
| Separazione dei servizi | Apache/PHP, SSH e MariaDB vivono nello stesso container e sono avviati tramite `service` da `init.sh`. | Separare almeno MariaDB in un servizio Compose dedicato; valutare un servizio per il web e uno per SSH/laboratorio. Questo limita i privilegi, consente aggiornamenti indipendenti e rende piu' chiari backup e healthcheck. |
| Supervisione | Il processo principale e' uno script shell che avvia servizi SysV e resta attivo con `tail -f`. Il healthcheck verifica esclusivamente HTTP. | Usare un processo principale per container o un init leggero; definire healthcheck distinti per web e database e una readiness verificata prima del bootstrap degli utenti. |
| Isolamento utenti | Il codice PHP degli studenti viene eseguito da Apache; `AllowOverride All` e `Options Indexes` sono abilitati in tutte le directory web personali. | Disabilitare `Indexes`, limitare gli override ai soli direttivi indispensabili o disabilitarli, e valutare PHP-FPM/pool separati o container effimeri per gli esercizi che eseguono codice non fidato. |
| Hardening runtime | Mancano `read_only`, `no-new-privileges`, limiti PID e `tmpfs` espliciti. | Dopo la separazione dei servizi, adottare filesystem root read-only per le immagini che lo permettono, `security_opt: no-new-privileges:true`, `pids_limit`, `tmpfs` per runtime e limiti `ulimits`. I path che devono restare scrivibili vanno dichiarati esplicitamente. |
| Risorse | I limiti del singolo container non isolano studenti o processi. Le quote filesystem invocate nello script potrebbero non essere supportate da un bind mount. | Validare le quote sul filesystem di produzione; aggiungere limiti per processi e, per esercizi potenzialmente onerosi, eseguire i workload in container temporanei con CPU, memoria e timeout dedicati. |
| Rete | La rete esterna `nginx-proxy-network` deve esistere prima del deploy, ma non e' definita dal progetto. Le label mescolano convenzioni Traefik e nginx-proxy-manager. | Formalizzare il prerequisito in IaC o fornire un file Compose di infrastruttura che crei la rete. Scegliere un solo reverse proxy e mantenere solo label compatibili con quello adottato. |
| Configurazione | Le variabili `MYSQL_ROOT_PASSWORD`, `MYSQL_USER` e `MYSQL_PASSWORD` nel Compose non governano la configurazione effettiva, che e' codificata nel Dockerfile e negli script. | Rendere ogni impostazione runtime effettivamente parametrica, validarla all'avvio e rimuovere variabili inutilizzate. Non usare segreti come argomenti, label o variabili visibili con `docker inspect`. |
| Manutenibilita' | Nel file Compose sono dichiarati named volume `home_data` e `mysql_data`, ma il servizio usa invece bind mount; sono quindi configurazione morta. | Eliminare le definizioni non usate oppure usarle davvero. Ridurre i commenti che descrivono un comportamento diverso dalla configurazione effettiva. |
| Supply chain | Adminer e le risorse web sono copiati dal repository nell'immagine senza una procedura dichiarata di aggiornamento e verifica. | Registrare versione, provenienza e checksum degli artefatti di terze parti; introdurre scansione immagini e aggiornamenti periodici delle dipendenze. |

## Percorso di adozione consigliato

1. **Mettere in sicurezza l'esposizione:** sostituire e rimuovere tutte le
   password note, chiudere la porta MySQL pubblica, restringere le porte
   pubblicate e rimuovere `SYS_ADMIN`.
2. **Rendere la build riproducibile:** introdurre `.dockerignore`, digest e
   versioni fissate, poi verificare la build in CI.
3. **Rendere dichiarativi i prerequisiti:** aggiungere un file
   `.env.example` senza segreti, un Compose di produzione con override
   espliciti e documentazione per rete esterna, directory persistenti, firewall
   e backup.
4. **Separare e ridurre i privilegi:** estrarre MariaDB dal container
   applicativo, applicare hardening e healthcheck per servizio, quindi
   rivalutare le quote e l'esecuzione isolata degli esercizi.

## Criteri di accettazione per l'evoluzione IaC

- Un clone del repository, senza dati locali, puo' produrre lo stesso ambiente
  da versioni fissate.
- Nessun segreto e nessun dato studente entra nel contesto di build o nel
  controllo di versione.
- Il database non e' raggiungibile dall'esterno salvo una scelta esplicita,
  autenticata e cifrata.
- Il deploy fallisce con un messaggio chiaro se mancano rete, secret o volumi
  richiesti, anziche' avviarsi con credenziali predefinite.
- Le home e i dati MariaDB restano persistenti e ripristinabili durante la
  migrazione, in coerenza con il flusso di ripristino degli account esistente.
