#!/bin/bash

# Skripti eesmärk: Loob kasutajad kahest eraldi failist (nimed ja paroolid)
# ja seadistab kodukataloogid. Ei kutsu ühtegi lisaskripti.

# --- 1. Kasutamise õigsuse kontroll ---
if [ $# -ne 2 ]; then
    echo "Kasutusjuhend: $0 <kasutajanimede_fail> <paroolide_fail>"
    echo "Näide: $0 kasutajad_nimed kasutajad_paroolid"
    exit 1
fi

# --- 2. Parameetrite ja failikontroll ---
NIMEDE_FAIL=$1
PAROOLIDE_FAIL=$2

# Kontrolli failide olemasolu ja loetavust
if [ ! -f "$NIMEDE_FAIL" ] || [ ! -r "$NIMEDE_FAIL" ] || [ ! -f "$PAROOLIDE_FAIL" ] || [ ! -r "$PAROOLIDE_FAIL" ]; then
    echo "Viga: Üks või mõlemad sisendfailid puuduvad või pole loetavad."
    exit 2
fi

# --- 3. Loendurite ja loop'ide seadistamine ---
# Loeme failid massiividesse (turvalisem kui read-while-do)
mapfile -t NIMED_ARRAY < "$NIMEDE_FAIL"
mapfile -t PAROOLID_ARRAY < "$PAROOLIDE_FAIL"

# Kontrolli, kas failides on sama arv ridu
if [ "${#NIMED_ARRAY[@]}" -ne "${#PAROOLID_ARRAY[@]}" ]; then
    echo "Viga: Kasutajanimede ja paroolide failid ei sisalda sama arvu ridu."
    exit 3
fi

# --- 4. Kasutajate loomise ja paroolide määramise loop ---
echo "Alustatakse kasutajate loomist ja paroolide määramist..."

for (( i=0; i<${#NIMED_ARRAY[@]}; i++ )); do
    KASUTAJANIMI=${NIMED_ARRAY[i]}
    PAROOL=${PAROOLID_ARRAY[i]}

    # Jäta vahele tühjad read
    if [ -z "$KASUTAJANIMI" ] || [ -z "$PAROOL" ]; then
        continue
    fi

    echo "Töödeldakse kasutajat: $KASUTAJANIMI"

    # Kontrolli, kas kasutaja juba eksisteerib
    if id "$KASUTAJANIMI" &>/dev/null; then
        echo "Viga: Kasutaja '$KASUTAJANIMI' on juba süsteemis olemas. Jäetakse vahele."
        continue # Mine järgmise kasutaja juurde
    fi

    # 4a. Kasutaja loomine (useradd käsk)
    # useradd -m -k /etc/skel -s /bin/bash on parim lahendus vastavalt eelnevale tööle.
    useradd -m -k /etc/skel -s /bin/bash "$KASUTAJANIMI"

    LOOMISE_TULEMUS=$?

    if [ $LOOMISE_TULEMUS -eq 0 ]; then
        # 4b. Parooli määramine (chpasswd käsk)
        echo "$KASUTAJANIMI:$PAROOL" | chpasswd

        if [ $? -eq 0 ]; then
            echo "Kasutaja '$KASUTAJANIMI' loodud ja parool määratud edukalt."
        else
            echo "Viga: Parooli määramisel tekkis probleem."
        fi
    else
        echo "Kriitiline Viga: Kasutaja '$KASUTAJANIMI' loomine ebaõnnestus."
    fi
done

echo "Töö lõpetatud."
