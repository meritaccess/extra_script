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


# enable uart4 for osdp communication
uart_enabled=$(grep "^dtoverlay=uart4" /boot/config.txt)
if [ -z $uart_enabled ]; then
    echo "dtoverlay=uart4" | sudo tee -a /boot/config.txt
    log_message "UART4 overlay enabled. Rebooting system."
    sudo reboot
else
    log_message "UART4 overlay is already enabled."
fi