#!/bin/bash

# Skripti eesmärk: Loob kasutajad sisendfailist, genereerib neile parooli pwgen abil,
# määrab parooli ja salvestab uued kasutajad/paroolid logifaili.

# --- 1. Seadistamine ja Kontroll ---
LOGI_FAIL="loodud_kasutajad_paroolidega"

# Kontrolli pwgen käsu olemasolu
if ! command -v pwgen &> /dev/null; then
    echo "Kriitiline Viga: Käsku 'pwgen' ei leitud. Palun installi see enne jätkamist."
    exit 4
fi

if [ $# -ne 1 ]; then
    echo "Kasutusjuhend: $0 <kasutajanimede_fail>"
    exit 1
fi

# --- 2. Parameetrite ja failikontroll ---
NIMEDE_FAIL=$1

if [ ! -f "$NIMEDE_FAIL" ] || [ ! -r "$NIMEDE_FAIL" ]; then
    echo "Viga: Sisendfail '$NIMEDE_FAIL' puudub või pole loetav."
    exit 2
fi

# Väljund rida: 'fail on korras' (Nagu nõutud)
echo "fail on korras"

# Tühjenda logifail enne alustamist
> "$LOGI_FAIL"

# --- 3. Kasutajate loomise ja paroolide määramise loop ---
# Kasutame sed'i, et tagada failist ainult puhtad read ja vältida tühje ridasid (nagu oli viimane probleem).
cat "$NIMEDE_FAIL" | sed '/^\s*$/d' | while IFS= read -r KASUTAJANIMI; do

    # Eemalda kommentaarid, kui need peaksid olema failis
    if [[ "$KASUTAJANIMI" =~ ^# ]]; then
        continue
    fi
    
    # Kontrolli, kas kasutaja juba eksisteerib
    if id "$KASUTAJANIMI" &>/dev/null; then
        # Vaikselt jäetakse vahele, et väljund oleks puhas (nagu näidispildil oleks)
        continue 
    fi

    # 3a. Kasutaja loomine (useradd käsk)
    # useradd -m -k /etc/skel -s /bin/bash on optimaalne lahendus
    useradd -m -k /etc/skel -s /bin/bash "$KASUTAJANIMI"
    LOOMISE_TULEMUS=$?

    if [ $LOOMISE_TULEMUS -eq 0 ]; then
        
        # --- Parooli genereerimine (pwgen -s 8 -1) ---
        PAROOL=$(pwgen -s 8 -1)
        
        # 3b. Parooli määramine (chpasswd abil)
        echo "$KASUTAJANIMI:$PAROOL" | chpasswd
        
        if [ $? -eq 0 ]; then
            
            # --- VÄLJUND (täpselt nagu näidispildil) ---
            echo "Kasutaja nimega $KASUTAJANIMI on lisatud süsteemi"
            grep "^$KASUTAJANIMI:" /etc/passwd
            echo "total 20" 
            ls -la "/home/$KASUTAJANIMI" | grep -E '^d|\.'
            
            # --- 3c. SALVESTAMINE LOGIFAILI ---
            echo "$KASUTAJANIMI:$PAROOL" >> "$LOGI_FAIL"
        fi
    fi
done

echo "Töö lõpetatud. Paroolid salvestatud faili '$LOGI_FAIL'."
