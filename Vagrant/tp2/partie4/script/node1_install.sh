#!/bin/bash

# Auriol Thomas
# 30/09/2020
# Configuration de node1 pour la partie 4 tp2

# Création des utilisateurs
# User admin
useradd admin -m
usermod admin -aG wheel

# User web
useradd web -M -s /sbin/nologin

# User backup
useradd backup
usermod backup -aG web

# Gestion des droits pour les certificats
chmod 400 /etc/pki/tls/private/server.key
chown web:web /etc/pki/tls/private/server.key
chown web:web /etc/pki/tls/certs/server.crt
chmod 444 /etc/pki/tls/certs/server.crt

# Activation de nginx au démarage
systemctl enable nginx
systemctl start nginx

# Création des sites 1 et 2
mkdir /srv/site1/
touch /srv/site1/index.html
echo '<h1>Hello world 1</h1>' | tee /srv/site1/index.html

mkdir /srv/site2/
touch /srv/site2/index.html
echo '<h1>Hello world 2</h1>' | tee /srv/site2/index.html

# Gestion des droits pour web
chown web:web /srv/site1 -R
chown web:web /srv/site2 -R
chmod 550 /srv/site1 /srv/site2
chmod 440 /srv/site1/index.html /srv/site2/index.html

# Trust le certificats
cp /etc/pki/tls/certs/server.crt /usr/share/pki/ca-trust-source/anchors/
update-ca-trust

rm -r /tmp/ssl/

# Backup automatique
cp /tmp/backup.sh /opt/
mkdir /opt/backup
rm /tmp/backup.sh

# Droits backup files
chown backup:backup /opt/backup.sh
chown backup:backup  /opt/backup/ -R
chmod 700 /opt/backup/
chmod 500 /opt/backup.sh

# Crontab backup
(crontab -u backup -l ; echo "* */1 * * * /opt/backup.sh /srv/site1") | crontab -u backup -
(crontab -u backup -l ; echo "* */1 * * * /opt/backup.sh /srv/site2") | crontab -u backup -

# Installation netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait
firewall-cmd --add-port=19999/tcp --permanent
firewall-cmd --reload