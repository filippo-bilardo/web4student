# Web4Student - Istruzioni progetto

## Scopo

Web4Student e` un ambiente Docker multiutente per didattica di programmazione e sviluppo web. Il container espone Apache, SSH e MySQL/MariaDB e crea un ambiente personale per ogni studente con home, area web e database dedicato.

## File chiave

- `docker-compose.yml`: servizio principale `web4student`, porte esposte, volumi persistenti, variabili ambiente e healthcheck.
- `manage.sh`: entrypoint operativo per avvio, shell, log, creazione utenti e ripristino account.
- `scripts/init.sh`: bootstrap del container; ripristina stato account persistente, avvia servizi e riallinea gli utenti.
- `scripts/restore_persisted_accounts.sh`: ricrea account Linux partendo dalle home persistenti quando il container viene ricreato.

## Dati persistenti importanti

- `volumes/home`: home directory degli utenti; e` la fonte principale per ricostruire gli account Linux.
- `volumes/mysql_data`: dati MySQL/MariaDB persistenti.
- `volumes/students.csv`: elenco studenti usato per il bootstrap iniziale.
- Stato account Linux persistente: salvato sotto `/home/shared/.web4student/auth-state` dentro il volume delle home.

## Flusso di avvio

All'avvio `scripts/init.sh`:

1. ripristina `passwd`, `shadow`, `group` e `gshadow` persistiti;
2. prepara la home del docente `prof`;
3. avvia MySQL/MariaDB, SSH e Apache;
4. crea utenti da `/home/students.csv` se presente;
5. esegue `restore_persisted_accounts.sh` per recuperare account mancanti ma presenti nei volumi;
6. esporta di nuovo lo stato account e avvia la sincronizzazione in background.

## Comandi operativi da preferire

- `./manage.sh start`
- `./manage.sh status`
- `./manage.sh create-users`
- `./manage.sh restore-users`
- `./manage.sh configure-aliases`
- `./manage.sh logs`

## Vincoli funzionali

- Le password Linux degli studenti devono restare persistenti anche dopo restart/recreate del container.
- `restore-users` deve ricostruire gli account mancanti senza toccare le home gia` persistenti.
- Le cartelle tecniche `shared` e `.web4student` non vanno trattate come home studente.
- La derivazione dello username dalle home deve restare compatibile con la logica in `restore_persisted_accounts.sh`.

## Credenziali e convenzioni attuali

- SSH docente: `prof` / `prof123`
- MySQL admin: `admin` / `admin123`
- Password iniziale studenti: `student123`
- Database studente: `db_<username>`

## Note per modifiche future

- Conservare la documentazione e i messaggi operativi in italiano.
- Prima di modificare bootstrap o restore, considerare sia la creazione da CSV sia il recupero da volumi persistenti.
- Evitare cambiamenti che rompano la compatibilita` con installazioni gia` avviate e con i dati presenti in `volumes/home`.
