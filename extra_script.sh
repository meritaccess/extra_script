#!/bin/bash
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /home/meritaccess/logs/update.log
}

log_message "Extra script started."

CONFIG_FILE="/etc/mysql/mariadb.cnf"

# Check for [mysqld]
if ! grep -q "^\[mysqld\]" "$CONFIG_FILE"; then
    echo "[mysqld]" >> "$CONFIG_FILE"
fi

# check for event_scheduler = ON
if ! grep -q "^event_scheduler\s*=\s*ON" "$CONFIG_FILE"; then
    sed -i "/^\[mysqld\]/a event_scheduler = ON" "$CONFIG_FILE"
fi

log_message "Mysql configuration finished"
