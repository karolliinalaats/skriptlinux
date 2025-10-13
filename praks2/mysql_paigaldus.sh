#!/usr/bin/env bash
# mysql_paigaldus.sh — kontrollib, paigaldab (kui vaja) ja näitab MySQL/MariaDB staatust
# Debiani/Ubuntu süsteemidele.

set -euo pipefail

# --- helper: check if a package is installed ---------------------------------
is_installed () {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"
}

echo ">>> Kontrollin MySQL/MariaDB olemasolu ..."

PKG=""            # paigaldatav pakett (kui vaja)
SERVICE=""        # teenuse nimi

# 1) kas mysql-server on juba olemas?
if is_installed mysql-server; then
  PKG="mysql-server"
  echo "OK: mysql-server on juba paigaldatud."
# 2) kas mariadb-server on juba olemas?
elif is_installed mariadb-server; then
  PKG="mariadb-server"
  echo "OK: mariadb-server on juba paigaldatud."
# 3) kumbki pole — vali mõistlik meta-pakett
else
  # Debian/Ubuntu pakuvad tavaliselt meta-paketti 'default-mysql-server'
  # mis toob kaasa kas MySQL-i või MariaDB. Kui see puudub, proovime mariadb-serverit.
  if apt-cache policy default-mysql-server | grep -q Candidate; then
    PKG="default-mysql-server"
  else
    PKG="mariadb-server"
  fi
  echo "PAIGALDAN: $PKG (MySQL/MariaDB server ei ole paigaldatud)."
  sudo apt-get update -y
  sudo apt-get install -y "$PKG"
  echo "Valmis: $PKG on paigaldatud."
fi

# --- leia tegelik teenuse nimi (mysql või mariadb) ---------------------------
if systemctl list-unit-files | grep -q "^mysql\.service"; then
  SERVICE="mysql"
elif systemctl list-unit-files | grep -q "^mariadb\.service"; then
  SERVICE="mariadb"
else
  # fallback – vanemad süsteemid võivad kasutada 'mysql'
  SERVICE="mysql"
fi

echo
echo ">>> Käivitan teenuse ja näitan staatust: $SERVICE"

# käivita ja luba automaatne start
sudo systemctl enable --now "$SERVICE" >/dev/null 2>&1 || true

# kuva lühike staatusekokkuvõte
if systemctl is-active --quiet "$SERVICE"; then
  echo "Teenuse seisund: ACTIVE (running)"
else
  echo "Hoiatus: teenus ei ole aktiivne. Proovin käivitada..."
  sudo systemctl start "$SERVICE" || true
fi

echo
sudo systemctl --no-pager --full status "$SERVICE" || true

echo
echo ">>> Tööd tehtud."
