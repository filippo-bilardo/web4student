# 🚀 Web4Student - Guida per il troubleshooting e il Debug

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

### Verifica dimensione occupata dall'immagine e dal container
```bash
docker images
docker ps -s
docker system df

```

### elimino gli utenti
```bash
cd /ws/container/web4student && docker exec web4student bash -c '
# Lista degli utenti studenti da eliminare
STUDENTS="ammirati.massimiliano ayalachacon.sebastie battaglia.valerio biroli.lucia elsi.federico giudici.joseabel lucchetti.andrea mansi.edoardo marsano.valerio marzi.riccardo mauro.simone narciso.michele paredesloor.marcoantonio raballo.enrico ronchi.angelo sesti.luca viscomi.nicolo vodola.christian"

echo "🗑️ Eliminazione studenti..."

for username in $STUDENTS; do
    echo "Eliminando utente: $username"
    
    # Elimina il database dell utente
    mysql -u root -e "DROP DATABASE IF EXISTS db_$username;" 2>/dev/null
    mysql -u root -e "DROP USER IF EXISTS \"$username\"@\"localhost\";" 2>/dev/null
    mysql -u root -e "DROP USER IF EXISTS \"$username\"@\"%\";" 2>/dev/null
    
    # Elimina lutente dal sistema
    userdel -r "$username" 2>/dev/null
    
    echo "✅ Eliminato: $username"
done

# Elimina le directory delle classi se vuote
echo "🧹 Pulizia directory classi..."
find /home -maxdepth 1 -type d -empty -exec rmdir {} \; 2>/dev/null

echo "🎉 Eliminazione completata!"
'
```


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

