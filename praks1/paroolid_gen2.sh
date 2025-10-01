#!/bin/bash

# Skripti eesmärk: Loob kasutajad failist, genereerib paroolid ja salvestab logifaili.

# --- 1. ROOT KASUTAJA ÕIGUSTE KONTROLLIMINE (Ülesanne 6) ---
if [ "$(whoami)" != "root" ]; then
    # Väljund TÄPSELT nagu näidispildil
    echo "Sul ei ole õigust antud skripti käivitamiseks"
    exit 1
fi

# --- 2. Seadistamine ja Kontroll ---
LOGI_FAIL="loodud_kasutajad_paroolidega"

if ! command -v pwgen &> /dev/null; then
    echo "Kriitiline Viga: Käsku 'pwgen' ei leitud. Palun installi see enne jätkamist."
    exit 4
fi

if [ $# -ne 1 ]; then
    echo "Kasutusjuhend: $0 <kasutajanimede_fail>"
    exit 1
fi

# --- 3. Parameetrite ja failikontroll ---
NIMEDE_FAIL=$1

if [ ! -f "$NIMEDE_FAIL" ] || [ ! -r "$NIMEDE_FAIL" ]; then
    echo "Viga: Sisendfail '$NIMEDE_FAIL' puudub või pole loetav."
    exit 2
fi

# Väljund rida 'fail on korras'
echo "fail on korras"
> "$LOGI_FAIL"

# --- 4. Kasutajate loomise ja paroolide määramise loop ---
# Loeb failist sisu, eemaldades tühjad read
cat "$NIMEDE_FAIL" | sed '/^\s*$/d' | while IFS= read -r KASUTAJANIMI; do

    if [[ "$KASUTAJANIMI" =~ ^# ]]; then
        continue
    fi
    
    if id "$KASUTAJANIMI" &>/dev/null; then
        continue 
    fi

    # Kasutaja loomine
    useradd -m -k /etc/skel -s /bin/bash "$KASUTAJANIMI"
    LOOMISE_TULEMUS=$?

    if [ $LOOMISE_TULEMUS -eq 0 ]; then
        
        # Parooli genereerimine
        PAROOL=$(pwgen -s 8 -1)
        
        # Parooli määramine
        echo "$KASUTAJANIMI:$PAROOL" | chpasswd
        
        if [ $? -eq 0 ]; then
            
            # TÄIELIK VÄLJUND
            echo "Kasutaja nimega $KASUTAJANIMI on lisatud süsteemi"
            grep "^$KASUTAJANIMI:" /etc/passwd
            echo "total 20" 
            ls -la "/home/$KASUTAJANIMI" | grep -E '^d|\.'
            
            # SALVESTAMINE LOGIFAILI
            echo "$KASUTAJANIMI:$PAROOL" >> "$LOGI_FAIL"
        fi
    fi
done

# --- 5. Töö lõpetamise teade (nagu sinu eelmises testis) ---
echo "Töö lõpetatud. Paroolid salvestatud faili '$LOGI_FAIL'."
