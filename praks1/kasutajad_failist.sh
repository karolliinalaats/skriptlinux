#!/bin/bash

# --- 1. Kasutamise õigsuse kontroll ---
if [ $# -ne 1 ]; then
    echo "Kasutusjuhend: $0 <failinimi>"
    exit 1
else
    FAILINIMI=$1
    # Kontrolli, kas fail eksisteerib ja on loetav
    if [ ! -f "$FAILINIMI" ] || [ ! -r "$FAILINIMI" ]; then
        echo "Faili '$FAILINIMI' ei leitud või see pole loetav."
        exit 2
    fi

    # Väljund rida: 'fail on korras' (Ainult see rida jääb juhtskriptist väljundisse)
    echo "fail on korras"

    # --- 2. Kasutajate loomise loop ---
    while read nimi; do
        # Jäta vahele tühjad read ja kommentaarid
        if [ -z "$nimi" ] || [[ "$nimi" =~ ^# ]]; then
            continue
        fi

        # Kutsub skripti lisa_kasutaja.sh (mis teeb kogu väljunditöö)
        ./lisa_kasutaja.sh "$nimi"

    done < "$FAILINIMI"
fi
