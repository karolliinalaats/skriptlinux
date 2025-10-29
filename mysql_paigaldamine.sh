#!/bin/bash
# mysql-server paigaldusskript

# kontrollime, mitu korda mysql-server korral ok installed
# sõnad on leitud ja vastus salvestame
# muutuja määramine:
MYSQL=$(dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -c "ok installed")

# kui MYSQL muutuja väärtus võrdub 0-ga
if [ "$MYSQL" -eq 0 ]; then
    # siis ok installed ei ole leitud
    # ja väljastame vastav teade ning
    # paigaldame teenuse
    echo "Paigaldame mysql ja vajalikud lisad"
    apt install -y mysql-server
    echo "mysql on paigaldatud"

    # lisame võimalus kasutada mysql käsk ilma kasutaja ja parooli lisamiseta
    touch "$HOME/.my.cnf"
    # lisame vajaliku konfiguratsioonifaili antud kasutaja kodukausta
    echo "[client]" > "$HOME/.my.cnf"
    echo "host = localhost" >> "$HOME/.my.cnf"
    echo "user = root" >> "$HOME/.my.cnf"
    echo "password = qwerty" >> "$HOME/.my.cnf"

# kui MYSQL muutuja väärtus võrdub 1-ga
elif [ "$MYSQL" -eq 1 ]; then
    # siis ok installed on leitud 1 kord
    # ja teenus on juba paigaldatud
    echo "mysql-server on juba paigaldatud"
    # kontrollime olemasolu
    mysql --version
fi

# skripti lõpp
