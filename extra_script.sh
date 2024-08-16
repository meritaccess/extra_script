#!/bin/bash
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /home/meritaccess/logs/update.log
}

log_message "Extra script started."

# Definice cesty k souboru
CONFIG_FILE="/etc/mysql/mariadb.cnf"

# Zkontroluje, zda soubor obsahuje sekci [mysqld]
if ! grep -q "^\[mysqld\]" "$CONFIG_FILE"; then
    echo "[mysqld]" >> "$CONFIG_FILE"
fi

# Zkontroluje, zda soubor obsahuje položku event_scheduler = ON
# Pokud ne, přidá ji pod sekci [mysqld]
if ! grep -q "^event_scheduler\s*=\s*ON" "$CONFIG_FILE"; then
    sed -i "/^\[mysqld\]/a event_scheduler = ON" "$CONFIG_FILE"
fi

log_message "Kontrola a úprava konfigurace dokončena."