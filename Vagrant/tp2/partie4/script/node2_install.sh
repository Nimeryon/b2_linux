#!/bin/bash

# Auriol Thomas
# 30/09/2020
# Configuration de node2 pour la partie 4 tp2

# Config /etc/hosts
echo "192.168.2.11 node1.tp2.b2" >> /etc/hosts

# Trust le certificats
cp /tmp/ssl/server.crt /usr/share/pki/ca-trust-source/anchors/
update-ca-trust

rm -r /tmp/ssl/