#!/usr/bin/env bash
set -e

# ------------------ KONFIGURATSIOON ------------------
DB_NAME=wordpress          # Andmebaasi nimi
DB_USER=wpuser             # Andmebaasi kasutaja nimi
DB_PASS=qwerty             # Andmebaasi kasutaja parool
WEB_DIR=/var/www/html/wordpress   # WordPressi kausta asukoht
# -----------------------------------------------------

echo "[1] Paigaldan vajalikud paketid..."
sudo apt update -y
sudo apt install -y apache2 php php-mysql mariadb-server wget curl

echo "[2] Käivitan teenused (MariaDB ja Apache)..."
sudo systemctl enable --now mariadb apache2

echo "[3] Loon andmebaasi ja kasutaja (kui neid veel pole)..."
sudo mysql <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

echo "[4] Laen alla ja pakin WordPressi (vajadusel)..."
sudo mkdir -p /var/www/html
if [ ! -d "$WEB_DIR" ]; then
  echo " - WordPressi kausta ei leitud, laen alla ja pakin..."
  sudo sh -c "wget -qO- https://wordpress.org/latest.tar.gz | tar xz -C /var/www/html"
else
  echo " - WordPress on juba olemas: $WEB_DIR"
fi

echo "[5] Loon wp-config.php faili (kui puudub)..."
if [ ! -f "$WEB_DIR/wp-config.php" ]; then
  sudo cp "$WEB_DIR/wp-config-sample.php" "$WEB_DIR/wp-config.php"
  # Asendan andmebaasi ühenduse andmed
  sudo sed -i \
    -e "s/database_name_here/${DB_NAME}/" \
    -e "s/username_here/${DB_USER}/" \
    -e "s/password_here/${DB_PASS}/" \
    "$WEB_DIR/wp-config.php"
  # Lisame WordPressi turvavõtmed (soolad)
  SALTS=$(curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/ || true)
  if [ -n "$SALTS" ]; then
    sudo awk -v s="$SALTS" '
      BEGIN{p=1}
      /Authentication Unique Keys and Salts/{print "/* Authentication Unique Keys and Salts */"; print s; p=0}
      p{print}
      /End of salts/{p=1}
    ' "$WEB_DIR/wp-config.php" | sudo tee "$WEB_DIR/wp-config.php" >/dev/null
  fi
else
  echo " - wp-config.php juba olemas, ei muudeta."
fi

echo "[6] Seadistan õigused ja Apache konfiguratsiooni..."
sudo chown -R www-data:www-data "$WEB_DIR"
sudo find "$WEB_DIR" -type d -exec chmod 755 {} \;
sudo find "$WEB_DIR" -type f -exec chmod 644 {} \;

# Lubame mod_rewrite ja AllowOverride All
sudo a2enmod rewrite >/dev/null
echo '<Directory /var/www/html>
  AllowOverride All
  Require all granted
</Directory>' | sudo tee /etc/apache2/conf-available/wordpress-override.conf >/dev/null
sudo a2enconf wordpress-override.conf >/dev/null || true
sudo systemctl restart apache2

echo "[7] Kontrollin, kas WordPress töötab..."
if curl -fsI http://127.0.0.1/wordpress/ >/dev/null; then
  echo "WordPress on paigaldatud! Ava brauseris: http://<serveri-ip>/wordpress"
else
  echo "WordPressi failid asuvad kaustas $WEB_DIR. Kui leht ei avane, kontrolli tulemüüri või võrgu seadeid."
fi
