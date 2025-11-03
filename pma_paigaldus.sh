#!/usr/bin/env bash
# phpmyadmin paigaldusskript

# kontrollime, mitu korda phpmyadmin korral ok installed
# sõnad on leitud ja vastus salvestame
# muutujasse sisse:
PMA=$(dpkg-query -W -f='${Status}' phpmyadmin 2>/dev/null | grep -c 'ok installed')

# kui PMA muutuja väärtus võrdub 0-ga
if [ "$PMA" -eq 0 ]; then
    # siis ok installed ei ole leitud
    # ja väljastame vastav teade ning
    # paigaldame teenus
    echo "Paigaldame andmebaasi ja phpmyadmin teenuse"
    apt update -y
    apt install -y mariadb-server mariadb-client
    apt install -y phpmyadmin
    echo "phpmyadmin on paigaldatud"

# kui PMA muutuja väärtus võrdub 1-ga
elif [ "$PMA" -eq 1 ]; then
    # siis ok installed on leitud 1 kord
    # ja teenus on juba paigaldatud
    echo "phpmyadmin on juba paigaldatud"
    # kontrollime olemasolu
fi

# lõpetame tingimuslause
# skripti lõpp
