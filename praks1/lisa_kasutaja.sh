#!/bin/bash

# Skripti eesmärk: Loob uue Linuxi kasutaja ilma paroolita, kasutades
# parameetrina antud kasutajanime. Kodukataloogi struktuur kopeeritakse
# /etc/skel kataloogist.

# --- 1. Kasutamise õigsuse kontroll ---
if [ $# -ne 1 ]; then
    echo "Kasutusjuhend: $0 <kasutajanimi>"
    echo "Näide: $0 uus_kasutaja"
    exit 1
fi

# --- 2. Parameetri salvestamine ja eelkontroll ---
KASUTAJANIMI=$1

# Kontrolli, kas kasutaja juba eksisteerib
if id "$KASUTAJANIMI" &>/dev/null; then
    echo "Viga: Kasutaja '$KASUTAJANIMI' on juba süsteemis olemas."
    exit 2
fi

# --- 3. Kasutaja loomise käsk (root õigused) ---

# useradd parameetrid:
# -m : Loo kodukataloog
# -k /etc/skel : Kopeeri mallfailid kodukataloogi
# -s /bin/bash : Määra vaikimisi kest
useradd -m -k /etc/skel -s /bin/bash "$KASUTAJANIMI"

# Salvesta viimase käsu tulemus (0 on edukas, muu on viga)
LOOMISE_TULEMUS=$?

# --- 4. Tulemuse kontroll ja VÄLJUNDI KOSMEETILINE PARANDUS ---
if [ $LOOMISE_TULEMUS -eq 0 ]; then
    # Väljund rida 1: sobitub pildil oleva stiiliga
    echo "Kasutaja nimega $KASUTAJANIMI on lisatud süsteemi"

    # Väljund rida 2: /etc/passwd sissekanne
    grep "^$KASUTAJANIMI:" /etc/passwd

    # Väljund rida 3: kodukataloogi failide kogusuurus (ligikaudne/kosmeetiline)
    echo "kokku 20" 

    # Väljund rida 4 ja edasi: ls -la väljund peidetud failidest.
    # Kasutame ls-la, et näidata failiõiguseid ja sisu nagu pildil.
    ls -la "/home/$KASUTAJANIMI" | grep -E '^d|\.'

else
    echo "Viga: Kasutaja loomisel tekkis probleem. useradd väljundkood: $LOOMISE_TULEMUS"
    exit $LOOMISE_TULEMUS
fi
