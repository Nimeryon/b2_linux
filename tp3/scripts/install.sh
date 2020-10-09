#!/bin/bash

# Auriol Thomas
# 30/09/2020
# Configuration de la box pour le tp3

yum update
yum install epel-release -y
yum install nginx -y
yum install python3 -y

# Setup firewall
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --reload

# Selinux permisive
setenforce 0
sed -i 's/.*SELINUX=enforcing.*/SELINUX=permissive/' /etc/selinux/config

# User web
useradd web -M -s /sbin/nologin
echo 'web ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Placer le service ServerWeb au bon endroit
mv /tmp/systemd/units/ServerWeb.service /etc/systemd/system/
mv /tmp/systemd/units/Backup.service /etc/systemd/system/
mv /tmp/systemd/units/Backup.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable ServerWeb.service
systemctl start ServerWeb.service
systemctl start Backup.timer

# User backup
useradd backup
usermod backup -aG web

# Backup automatique
mv /tmp/systemd/conf/ /opt/
mkdir /opt/backups
mkdir /opt/site1
touch /opt/site1/index.html
echo "<h1>Hello there!!" >> /opt/site1/index.html

# Droits backup files
chown backup:backup /opt/conf -R
chown backup:backup /opt/site1 -R
chown backup:backup  /opt/backups/ -R
chmod 700 /opt/backups/
chmod 500 /opt/conf/*

rm -r /tmp/systemd