#!/bin/bash

set -euo pipefail

HOME_ROOT="${1:-/ws/container/web4student/volumes/home}"
TOP_LIMIT="${TOP_LIMIT:-10}"
EXCLUDED_DIRS=("shared" ".web4student" "prof" "fb")

require_du_access() {
    if [ "$(id -u)" -eq 0 ]; then
        DU_CMD=(du)
        return
    fi

    if sudo -n true >/dev/null 2>&1; then
        DU_CMD=(sudo du)
        return
    fi

    echo "❌ Permessi insufficienti per leggere tutte le home studente." >&2
    echo "   Esegui lo script con sudo oppure abilita sudo senza prompt per questo comando." >&2
    exit 1
}

collect_class_dirs() {
    local find_args=()
    local dir_name

    for dir_name in "${EXCLUDED_DIRS[@]}"; do
        find_args+=('!' -name "$dir_name")
    done

    find "$HOME_ROOT" -mindepth 1 -maxdepth 1 -type d "${find_args[@]}" -printf '%P\n' | sort
}

format_relative_paths() {
    awk -F '\t' -v prefix="$HOME_ROOT/" 'BEGIN { OFS="\t" } { sub("^" prefix, "", $2); print $1, $2 }'
}

main() {
    local class_dirs=()
    local class_dir
    local student_globs=()

    if [ ! -d "$HOME_ROOT" ]; then
        echo "❌ Directory non trovata: $HOME_ROOT" >&2
        exit 1
    fi

    require_du_access
    shopt -s nullglob

    while IFS= read -r class_dir; do
        [ -n "$class_dir" ] || continue
        class_dirs+=("$class_dir")
        student_globs+=("$HOME_ROOT/$class_dir"/*)
    done < <(collect_class_dirs)

    if [ "${#class_dirs[@]}" -eq 0 ]; then
        echo "⚠️ Nessuna cartella studente trovata in $HOME_ROOT"
        exit 0
    fi

    if [ "${#student_globs[@]}" -eq 0 ]; then
        echo "⚠️ Nessuna home studente trovata nelle classi presenti in $HOME_ROOT"
        exit 0
    fi

    echo "Spazio usato dagli studenti: $("${DU_CMD[@]}" -sch -- "${student_globs[@]}" 2>/dev/null | tail -n 1 | cut -f1)"
    echo "Percorso: $HOME_ROOT"
    echo "Esclusi: ${EXCLUDED_DIRS[*]}"
    echo

    echo "Classi piu' pesanti"
    for class_dir in "${class_dirs[@]}"; do
        "${DU_CMD[@]}" -sh -- "$HOME_ROOT/$class_dir" 2>/dev/null
    done | sort -hr | format_relative_paths

    echo
    echo "Top ${TOP_LIMIT} studenti/cartelle piu' grandi"
    "${DU_CMD[@]}" -sh -- "${student_globs[@]}" 2>/dev/null | sort -hr | head -n "$TOP_LIMIT" | format_relative_paths
}

main "$@"
