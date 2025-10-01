#!/bin/bash

# Skripti eesmärk: Loob kasutajaid failist, mis sisaldab kasutajanimi:parool.

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

    echo "fail on korras"

    # --- 2. Kasutajate loomise ja paroolide määramise loop ---
    # Loeme failist read ja töötleme neid
    while read rida; do
        # Jäta vahele tühjad read ja kommentaarid
        if [ -z "$rida" ] || [[ "$rida" =~ ^# ]]; then
            continue
        fi

        # Eraldame kasutajanime (esimene osa koolonist -d :)
        KASUTAJANIMI=$(echo "$rida" | cut -d: -f1)
        # Eraldame parooli (teine osa koolonist)
        PAROOL=$(echo "$rida" | cut -d: -f2)

        # 2a. Loome kasutaja (kasutades varem loodud skripti)
        # NB! lisa_kasutaja.sh loob kasutaja ilma paroolita (* shadow failis)
        ./lisa_kasutaja.sh "$KASUTAJANIMI"

        # Kontrollime, kas loomine õnnestus (0 = edukas, 2 = juba olemas)
        LOOMISE_TULEMUS=$?

        if [ $LOOMISE_TULEMUS -eq 0 ]; then
            # 2b. Määra parool (AINULT, kui kasutaja loomine õnnestus)
            # chpasswd loeb inputi kujul KASUTAJANIMI:PAROOL
            echo "$KASUTAJANIMI:$PAROOL" | chpasswd

            # Kontrolli parooli määramise tulemust
            if [ $? -eq 0 ]; then
                echo "Parool määratud kasutajale '$KASUTAJANIMI' edukalt."
            else
                echo "Viga: Parooli määramisel tekkis probleem."
            fi
        fi

    done < "$FAILINIMI"
fi
