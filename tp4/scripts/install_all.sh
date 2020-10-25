#!/bin/bash

# Auriol Thomas
# 13/10/2020
# Configuration minimal des box tp4

yum update
yum install wget -y

# Selinux permisive
setenforce 0
sed -i 's/.*SELINUX=enforcing.*/SELINUX=permissive/' /etc/selinux/config

cat >> /etc/hosts <<EOL
192.168.4.11 gitea.tp4.b2 gitea
192.168.4.12 nginx.tp4.b2 nginx
192.168.4.13 nfs.tp4.b2   nfs
192.168.4.14 bdd.tp4.b2   bdd
EOL