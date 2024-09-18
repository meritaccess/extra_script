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

MERIT_CONF="/etc/apache2/sites-available/merit_access_web.conf"
PHPMYADMIN_CONF="/etc/apache2/sites-available/phpmyadmin.conf"
APACHE_CONF="/etc/apache2/apache2.conf"

create_merit_access_web_conf() {
    if [ ! -f "$MERIT_CONF" ]; then
        log_message "Creating $MERIT_CONF..."
        sudo tee "$MERIT_CONF" > /dev/null <<EOL
<VirtualHost *:80>
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/merit_access_web_error.log
    CustomLog \${APACHE_LOG_DIR}/merit_access_web.log combined
        RewriteEngine On

    # Capture the server's current IP dynamically
    RewriteCond %{HTTP_HOST} !^localhost [NC]
    RewriteCond %{SERVER_ADDR} (.*)
    RewriteRule ^/phpmyadmin$ http://%1:8081/phpmyadmin [R=301,L]
</VirtualHost>
EOL
    else
        log_message "$MERIT_CONF already exists, skipping creation."
    fi
}


create_phpmyadmin_conf() {
    if [ ! -f "$PHPMYADMIN_CONF" ]; then
        log_message "Creating $PHPMYADMIN_CONF..."
        sudo tee "$PHPMYADMIN_CONF" > /dev/null <<EOL
<VirtualHost *:8081>
    DocumentRoot /usr/share/phpmyadmin
    Alias /phpmyadmin /usr/share/phpmyadmin

    ErrorLog \${APACHE_LOG_DIR}/phpmyadmin_error.log
    CustomLog \${APACHE_LOG_DIR}/phpmyadmin_access.log combined

    <Directory /usr/share/phpmyadmin>
        Options FollowSymLinks
        DirectoryIndex index.php
        AllowOverride All
        Require all granted
    </Directory>

    Include /etc/phpmyadmin/apache.conf
</VirtualHost>
EOL
    else
        log_message "$PHPMYADMIN_CONF already exists, skipping creation."
    fi
}

modify_apache_conf() {
    # Add ServerName localhost if not present
    if ! grep -q "^ServerName localhost" "$APACHE_CONF"; then
        log_message "Adding 'ServerName localhost' to $APACHE_CONF..."
        log_message "ServerName localhost" | sudo tee -a "$APACHE_CONF"
    else
        log_message "'ServerName localhost' is already present in $APACHE_CONF."
    fi

    # Comment out the include /etc/phpmyadmin/apache.conf line if it's uncommented
    if grep -P '^\s*include\s+/etc/phpmyadmin/apache.conf' "$APACHE_CONF"; then
        log_message "Commenting out 'include /etc/phpmyadmin/apache.conf' in $APACHE_CONF..."
        sudo sed -i 's/^\(\s*include \/etc\/phpmyadmin\/apache.conf\)/#\1/' "$APACHE_CONF"
    else
        log_message "'include /etc/phpmyadmin/apache.conf' is already commented or absent in $APACHE_CONF."
    fi

    # Comment out the <Directory /var/www/> block only if it's not already commented
    if grep -q "^\s*<Directory /var/www/>" "$APACHE_CONF"; then
        log_message "Commenting out <Directory /var/www/> block in $APACHE_CONF..."
        sudo sed -i '/^\s*<Directory \/var\/www\/>/,/<\/Directory>/ s/^\s*#*/#/' "$APACHE_CONF"
    else
        log_message "'<Directory /var/www/>' block is already commented or doesn't exist."
    fi
}

enable_sites() {
    sudo a2enmod rewrite
    sudo systemctl restart apache2
    sudo a2ensite phpmyadmin.conf merit_access_web.conf
    sudo a2dissite 000-default.conf
    log_message "Reloading Apache..."
    sudo systemctl reload apache2
}


log_message "Starting Apache2 configuration"
create_merit_access_web_conf
create_phpmyadmin_conf
modify_apache_conf
enable_sites
log_message "Apache configuration setup completed."
