#!/bin/bash

# Mostra gli studenti loggati e l'utilizzo delle risorse del container.

set -u

print_separator() {
    printf '%s\n' "────────────────────────────────────────────────────────"
}

read_cpu_stats() {
    awk '/^cpu / { print $2+$3+$4+$5+$6+$7+$8, $5+$6 }' /proc/stat
}

format_bytes() {
    awk -v kib="$1" 'BEGIN {
        if (kib >= 1048576) printf "%.2f GiB", kib / 1048576
        else if (kib >= 1024) printf "%.2f MiB", kib / 1024
        else printf "%.0f KiB", kib
    }'
}

echo "📊 Stato del sistema Web4Student"
print_separator

echo "👥 Studenti attualmente loggati"
logged_students=$(who 2>/dev/null | awk '{print $1}' | sort -u)
if [ -n "$logged_students" ]; then
    printf '%s\n' "$logged_students" | while read -r username; do
        [ -n "$username" ] && printf '  • %s\n' "$username"
    done
else
    echo "  Nessuno studente loggato tramite una sessione riconosciuta."
fi

print_separator
echo "🧠 Utilizzo CPU"
cpu_before=$(read_cpu_stats)
sleep 1
cpu_after=$(read_cpu_stats)
awk -v before="$cpu_before" -v after="$cpu_after" 'BEGIN {
    split(before, b, " "); split(after, a, " ")
    total = a[1] - b[1]
    idle = a[2] - b[2]
    if (total > 0) printf "  Utilizzo: %.1f%%\n", (total - idle) * 100 / total
    else print "  Utilizzo: non disponibile"
}'
printf '  CPU disponibili: %s\n' "$(nproc 2>/dev/null || echo "n/d")"

print_separator
echo "💾 Utilizzo RAM"
mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
mem_available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
if [ -n "$mem_total" ] && [ -n "$mem_available" ]; then
    mem_used=$((mem_total - mem_available))
    printf '  Usata:       %s\n' "$(format_bytes "$mem_used")"
    printf '  Disponibile: %s\n' "$(format_bytes "$mem_available")"
    printf '  Totale:      %s\n' "$(format_bytes "$mem_total")"
    awk -v used="$mem_used" -v total="$mem_total" 'BEGIN {
        if (total > 0) printf "  Percentuale:  %.1f%%\n", used * 100 / total
    }'
else
    echo "  Informazioni RAM non disponibili."
fi
