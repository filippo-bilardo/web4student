# Cronologia delle modifiche

Questo documento riassume la storia del progetto ricostruita dalla cronologia
Git, dalla prima versione fino allo stato corrente del working tree.

## Storia Git

- **2025-09-11 — `0e5051b` — Initial commit**
  - Aggiunta della licenza del progetto.
- **2025-09-11 — `20b0643` — Initial commit: Web4Student container setup**
  - Introdotta l'infrastruttura Docker iniziale: `Dockerfile`, Compose,
    `manage.sh`, bootstrap, creazione account, gestione quote, MySQL, Adminer,
    homepage e documentazione.
- **2025-09-11 — `c738f7b` — Merge del repository remoto**
  - Allineamento con la storia del repository GitHub.
- **2025-09-11 — `7de9942` — Rimozione dati studenti sensibili**
  - Esclusione dei file con dati degli studenti dal controllo versione.
- **2025-09-11 — `d7e5ebe` — build 2**
  - Revisione estesa della documentazione, riorganizzazione dei README,
    miglioramenti alla creazione account e aggiunta dei test di sicurezza.
- **2025-09-11 — `4579958` — build 2**
  - Correzioni alla configurazione Compose.
- **2025-09-11 — `f3a3459` — build 2**
  - Aggiornamento del checklist operativo.
- **2025-09-11 — `e9446b8` — build 3**
  - Semplificazione del Dockerfile e degli script account; rimozione dello
    script legacy per la home del professore.
- **2025-09-11 — `112b0e0` — build 4**
  - Consolidamento del bootstrap e rimozione di script duplicati o non più
    necessari.
- **2025-09-11 — `7a0d6db` — build 5**
  - Riorganizzazione della documentazione in `docs/`, aggiunta delle immagini
    illustrative e ampliamento della homepage.
- **2025-09-11 — `e182636` — build 6**
  - Aggiornamento del checklist.
- **2025-09-11 — `15c6d80` — build 7**
  - Correzioni al checklist operativo.
- **2025-10-16 — `3885922` — build 8**
  - Aggiornamenti Compose e piccoli adeguamenti alla homepage.
- **2026-02-04 — `2687fb4` — build 9**
  - Aggiornamenti del Dockerfile per la costruzione dell'immagine.
- **2026-08-23 — `0b9b0bd` — gestione autenticazione e utilizzo home**
  - Aggiunti backup/ripristino dello stato account, ripristino dalle home
    persistenti e riepilogo dello spazio utilizzato.
- **2026-08-23 — `7f0c238` — esclusioni GitHub**
  - Aggiornato `.gitignore` per la configurazione GitHub locale.
- **2026-08-23 — `8d52559` — quote disco**
  - Aggiunta la configurazione iniziale delle quote utente nel container.
- **2026-08-23 — `20281ea` — file temporanei**
  - Aggiunte ulteriori esclusioni per file temporanei.
- **2026-08-24 — `a1d4d42` — credenziali amministrative da ambiente**
  - Parametrizzazione delle credenziali amministrative tramite `.env` e
    aggiunta dell'analisi IaC.
- **2026-08-24 — `66300d9` — contesto Docker più sicuro**
  - Aggiunto `.dockerignore` per escludere dati persistenti e sensibili dalla
    build.
- **2026-08-24 — `bae58f6` — helper Git push**
  - Aggiunto temporaneamente uno script per il push Git.
- **2026-08-24 — `7906589` — rimozione configurazione GitHub tracciata**
  - Smette di versionare la configurazione GitHub locale.
- **2026-08-24 — `b032681` — rimozione helper Git obsoleto**
  - Eliminato lo script di push non più necessario.
- **2026-09-03 — `6910b16` — favicon**
  - Aggiunta la favicon con il simbolo del tocco accademico.
- **2026-09-29 — `25fabfa` — monitoraggio e limiti processi**
  - Aggiunti monitoraggio CPU/RAM, limite di 100 processi per studente,
    configurazione dei limiti e script alias Apache sicuro.
- **2026-09-30 — `63de29d` — sito online**
  - Aggiornata la documentazione con gli indirizzi del servizio online.
- **2026-09-30 — `1ec7319` — update**
  - Aggiornata la documentazione operativa e di accesso.

## Modifiche presenti nel working tree corrente

Queste modifiche sono state raccolte nel commit con messaggio
`Persist web root and restore accounts automatically`:

- Spostamento delle password operative in `.env`/`.env.example`, con controlli
  all'avvio e rimozione delle password hardcoded da Dockerfile e script.
- Scadenza della password iniziale degli studenti al primo accesso (`chage`).
- Unificazione degli alias Apache in `configure_user_aliases.sh` e rimozione
  dello script legacy `configure_user_aliases_safe.sh`.
- Centralizzazione della creazione account CSV in `manage.sh`, incluso il
  comando `create-users-file` per CSV alternativi.
- Ripristino automatico degli account persistenti, alias, limiti processi,
  quote e stato autenticazione durante l'avvio del container.
- Correzione del rilevamento delle home persistenti per evitare la creazione di
  utenti errati come `5einf.5einf`.
- Aggiunti `configure_disk_quotas.sh`, `check_project.sh` e i comandi
  `configure-quotas`, `configure-limits` e `check`.
- Configurata la quota studenti a **8 MB soft / 10 MB hard**. Lo script segnala
  correttamente quando il filesystem host non espone quote utente attive.
- Rimossa la copia web duplicata nell'immagine e predisposto il DocumentRoot
  persistente `volumes/www`, montato automaticamente su `/var/www/html`.
- Copiati in `volumes/www` homepage, favicon, Adminer, documentazione
  infrastrutturale e pagina `4c.php`; le modifiche alla homepage non richiedono
  più una nuova build dell'immagine.
- Aggiornate le porte Compose: MySQL è disponibile solo su `127.0.0.1:3307`,
  HTTP/Node.js restano interni alla rete Docker, mentre SSH e le porte degli
  esercizi sono pubblicate esplicitamente.
- Aggiornata la documentazione README con bootstrap, ripristino account,
  gestione segreti, quote e controlli del progetto.

## Verifiche eseguite sullo stato corrente

- Sintassi degli script Bash verificata con `bash -n`.
- Configurazione verificata con `docker compose config --quiet`.
- Integrità whitespace verificata con `git diff --check`.
- `./manage.sh check` completato con esito positivo.

## Regola di manutenzione

Ogni push deve aggiornare questo file con il commit e le modifiche introdotte,
così la cronologia resta sincronizzata con il repository remoto.
- Container ricreato e account persistenti ripristinati automaticamente.
