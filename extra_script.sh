#!/bin/bash
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /home/meritaccess/logs/update.log
}

log_message "Extra script started."

CONFIG_FILE="/etc/mysql/mariadb.cnf"

# check for [mysqld]
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

# ensure correct hostname
current_hostname=$(hostname)
if [[ "$current_hostname" == *"cm4"* || "$current_hostname" == *"MDUD83ADD06DB00"* ]]; then
    mac_address_eth=$(ip link show eth0 | grep ether | awk '{print $2}')
    my_mdu=$(echo "$mac_address_eth" | tr -d ':')
    mdu=$(echo "MDU${my_mdu}" | awk '{print toupper($0)}')

    log_message "Current hostname: $current_hostname"
    log_message "MAC address eth0: $mac_address_eth"
    log_message "New hostname: $mdu"

    # update /etc/hosts – only if has old hostname
    sudo sed -i "s/127.0.1.1[[:space:]]\+$current_hostname/127.0.1.1       $mdu/" /etc/hosts

    # set new hostname
    sudo hostnamectl set-hostname "$mdu"
    log_message "Hostname was changed to $mdu"
else
    log_message "Hostname is not 'cm4' nor 'MDUD83ADD06DB00', it will not be changed."
fi


# set systemd-timesyncd
sudo systemctl unmask systemd-timesyncd
sudo systemctl enable systemd-timesyncd
sudo systemctl start systemd-timesyncd