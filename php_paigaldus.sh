#!/usr/bin/env bash
# php_paigaldamine.sh
# php paigaldusskript

# Kontrollime, kas PHP on juba paigaldatud
PHP=$(dpkg-query -W -f='${Status}' php 2>/dev/null | grep -c 'ok installed')

# Kui PHP pole paigaldatud
if [ "$PHP" -eq 0 ]; then
  echo "Paigaldame php ja vajalikud lisad"
  apt-get update -y
  apt-get install -y php libapache2-mod-php php-mysql
  echo "php on paigaldatud"

# Kui PHP on juba paigaldatud
elif [ "$PHP" -eq 1 ]; then
  echo "php on juba paigaldatud"
fi

# Kuvame php asukoha ja versiooni
echo
echo "php asukoht:"
which php || echo "php binaarfaili ei leitud PATH-ist"

echo
echo "php versioon:"
php -v | head -n 1 || echo "versiooni ei õnnestunud kuvada"
