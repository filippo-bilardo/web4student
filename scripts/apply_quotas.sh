#!/bin/bash

# Script per applicare quote disco a tutti gli utenti studenti esistenti
# Limite: 8MB soft, 10MB hard

echo "💾 Applicazione quote disco a tutti gli utenti studenti..."

# Trova tutti gli utenti con UID >= 1001 (studenti)
for user in $(awk -F: '$3 >= 1001 && $3 != 65534 {print $1}' /etc/passwd); do
    echo "  📏 Impostazione quota per utente: $user"
    
    # Imposta quota: 8MB soft limit, 10MB hard limit
    setquota -u "$user" 8192 10240 0 0 / 2>/dev/null || echo "    ⚠️ Errore nell'impostazione quota per $user"
    
    # Mostra la quota impostata
    quota -u "$user" 2>/dev/null || echo "    ⚠️ Impossibile visualizzare quota per $user"
done

echo "✅ Quote disco applicate!"
echo ""
echo "🔍 Per verificare le quote utilizzare:"
echo "  quota -u <username>    # Quota specifica utente"
echo "  repquota /             # Tutte le quote del sistema"
