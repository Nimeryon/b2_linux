# <u>*TP1 : Déploiement classique*</u>

## <u>*0. Prérequis*</u>

### <u>*Default*</u>

Configuration des deux cartes réseaux :

```
[root@localhost ~]# cat /etc/sysconfig/network-scripts/ifcfg-enp0s8

    DEVICE=enp0s8
    NAME=enp0s8

    BOOTPROTO=static
    ONBOOT=yes

    IPADDR=192.168.1.11
    NETMASK=255.255.255.0

[root@localhost ~]# cat /etc/sysconfig/network-scripts/ifcfg-enp0s3

    ...
    ONBOOT=yes
    DNS1=10.0.2.2
    DNS2=8.8.8.8
    ...
```

on reboot puis on ce connecte sur le ssh.

### <u>*Utilisateur*</u>

Je crée mon utilisateur "Admin" pour éviter de faire tout en root.

```
[root@localhost ~]# useradd admin
[root@localhost ~]# passwd admin
    passwd: all authentication tokens updated successfully.
```

On ajoute les droits d'éxecution des commandes sur notre groupe admin dans le fichier sudoers.

```
[root@localhost ~]# visudo
    ...
    %admin ALL=(ALL) ALL
    ...
```

### <u>*Hostname*</u>

```
[admin@localhost ~]$ sudo hostname node1.tp1.b2
[admin@localhost ~]$ sudo reboot
```

### <u>*Hosts*</u>

```
[admin@localhost ~]$ sudo cat /etc/hosts
    ...
    192.168.1.10 host.tp1.b2 host
    192.168.1.11 node1.tp1.b2 node1
    192.168.1.12 node2.tp1.b2 node2
```

### <u>*Firewall*</u>

On active les services http et https.

```
[admin@localhost ~]$ sudo firewall-cmd --zone=public --add-service=http --permanent
    success
[admin@localhost ~]$ sudo firewall-cmd --zone=public --add-service=https --permanent
    success
[admin@localhost ~]$ sudo firewall-cmd --reload
    success
[admin@localhost ~]$ sudo firewall-cmd --list-all
    public (active)
        ...
        services: dhcpv6-client http https ssh
        ports:
        ...
```

### <u>*PING*</u>

Avant de configurer la partition sur la première VM node1 on peut la dupliquer et changer l'hostname et l'ip de l'enp0s8.

Test de ping.

Node 1:
```
[admin@localhost ~]$ ping -c 3 node2
    PING node2.tp1.b2 (192.168.1.12) 56(84) bytes of data.
    64 bytes from node2.tp1.b2 (192.168.1.12): icmp_seq=1 ttl=64 time=0.627 ms
    64 bytes from node2.tp1.b2 (192.168.1.12): icmp_seq=2 ttl=64 time=0.298 ms
    64 bytes from node2.tp1.b2 (192.168.1.12): icmp_seq=3 ttl=64 time=0.264 ms

    --- node2.tp1.b2 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2004ms
    rtt min/avg/max/mdev = 0.264/0.396/0.627/0.164 ms
[admin@localhost ~]$ ping -c 3 host
    PING host.tp1.b2 (192.168.1.10) 56(84) bytes of data.
    64 bytes from host.tp1.b2 (192.168.1.10): icmp_seq=1 ttl=128 time=0.260 ms
    64 bytes from host.tp1.b2 (192.168.1.10): icmp_seq=2 ttl=128 time=0.200 ms
    64 bytes from host.tp1.b2 (192.168.1.10): icmp_seq=3 ttl=128 time=0.328 ms

    --- host.tp1.b2 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2001ms
    rtt min/avg/max/mdev = 0.200/0.262/0.328/0.055 ms
```

Node 2:
```
[admin@localhost ~]$ ping -c 3 node1
    PING node1.tp1.b2 (192.168.1.11) 56(84) bytes of data.
    64 bytes from node1.tp1.b2 (192.168.1.11): icmp_seq=1 ttl=64 time=0.380 ms
    64 bytes from node1.tp1.b2 (192.168.1.11): icmp_seq=2 ttl=64 time=0.382 ms
    64 bytes from node1.tp1.b2 (192.168.1.11): icmp_seq=3 ttl=64 time=0.330 ms

    --- node1.tp1.b2 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 1999ms
    rtt min/avg/max/mdev = 0.330/0.364/0.382/0.024 ms
[admin@localhost ~]$ ping -c 3 host
    PING host.tp1.b2 (192.168.1.10) 56(84) bytes of data.
    64 bytes from host.tp1.b2 (192.168.1.10): icmp_seq=1 ttl=128 time=0.191 ms
    64 bytes from host.tp1.b2 (192.168.1.10): icmp_seq=2 ttl=128 time=0.421 ms
    64 bytes from host.tp1.b2 (192.168.1.10): icmp_seq=3 ttl=128 time=0.338 ms

    --- host.tp1.b2 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2000ms
    rtt min/avg/max/mdev = 0.191/0.316/0.421/0.097 ms
```

### <u>*Partition*</u>

On récupère le nom du deuxième disque sur lequel on va monter les 2 partitions.

```
[admin@localhost ~]$ lsblk
    NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sda               8:0    0    8G  0 disk
    ├─sda1            8:1    0    1G  0 part /boot
    └─sda2            8:2    0    7G  0 part
    ├─centos-root 253:0    0  6.2G  0 lvm  /
    └─centos-swap 253:1    0  820M  0 lvm  [SWAP]
    sdb               8:16   0    6G  0 disk
    sr0              11:0    1 1024M  0 rom
    sr1              11:1    1 1024M  0 rom
```

Le disque s'appelle sdb. On l'ajout dans lvm en tant que disque physique.

```
[admin@localhost ~]$ sudo pvcreate /dev/sdb
    Physical volume "/dev/sdb" successfully created.
[admin@localhost ~]$ sudo pvs
    PV         VG     Fmt  Attr PSize  PFree
    /dev/sda2  centos lvm2 a--  <7.00g    0
    /dev/sdb          lvm2 ---   6.00g 6.00g
[admin@localhost ~]$ sudo pvdisplay
    --- Physical volume ---
    PV Name               /dev/sda2
    VG Name               centos
    PV Size               <7.00 GiB / not usable 3.00 MiB
    Allocatable           yes (but full)
    PE Size               4.00 MiB
    Total PE              1791
    Free PE               0
    Allocated PE          1791
    PV UUID               10dvFt-JzY6-9FDb-2jQG-uzO1-YhF5-wKjjQB

    "/dev/sdb" is a new physical volume of "6.00 GiB"
    --- NEW Physical volume ---
    PV Name               /dev/sdb
    VG Name
    PV Size               6.00 GiB
    Allocatable           NO
    PE Size               0
    Total PE              0
    Free PE               0
    Allocated PE          0
    PV UUID               Yen7xL-13Vp-OZLo-0efk-ncxw-By3e-XJ3FqF
```

Création du groupe volume.

```
[admin@localhost ~]$ sudo vgcreate data /dev/sdb
    Volume group "data" successfully created
[admin@localhost ~]$ sudo vgs
    VG     #PV #LV #SN Attr   VSize  VFree
    centos   1   2   0 wz--n- <7.00g     0
    data     1   0   0 wz--n- <6.00g <6.00g
[admin@localhost ~]$ sudo vgdisplay
    --- Volume group ---
    VG Name               data
    System ID
    Format                lvm2
    Metadata Areas        1
    Metadata Sequence No  1
    VG Access             read/write
    VG Status             resizable
    MAX LV                0
    Cur LV                0
    Open LV               0
    Max PV                0
    Cur PV                1
    Act PV                1
    VG Size               <6.00 GiB
    PE Size               4.00 MiB
    Total PE              1535
    Alloc PE / Size       0 / 0
    Free  PE / Size       1535 / <6.00 GiB
    VG UUID               QZqJUK-eeOU-Qxkk-D2HZ-dYpO-i2l2-gMoOnY

    --- Volume group ---
    VG Name               centos
    System ID
    Format                lvm2
    Metadata Areas        1
    Metadata Sequence No  3
    VG Access             read/write
    VG Status             resizable
    MAX LV                0
    Cur LV                2
    Open LV               2
    Max PV                0
    Cur PV                1
    Act PV                1
    VG Size               <7.00 GiB
    PE Size               4.00 MiB
    Total PE              1791
    Alloc PE / Size       1791 / <7.00 GiB
    Free  PE / Size       0 / 0
    VG UUID               IF0HPB-hoW1-6L34-USyd-NBje-7HMJ-XTCStU
```

Création des 2 volumes logique pour le site 1 et le site 2.

```
[admin@localhost ~]$ sudo lvcreate -L 2G data -n site1
    Logical volume "site1" created.
[admin@localhost ~]$ sudo lvcreate -L 3G data -n site2
    Logical volume "site2" created.
```

Montage des partitions au démarrage.

```
[admin@localhost ~]$ sudo mkfs -t ext4 /dev/data/site1
[admin@localhost ~]$ sudo mkfs -t ext4 /dev/data/site2
[admin@localhost ~]$ mkdir /mnt/site2
[admin@localhost ~]$ mkdir /mnt/site2
[admin@localhost ~]$ sudo mount /dev/data/site1 /mnt/site1
[admin@localhost ~]$ sudo mount /dev/data/site2 /mnt/site2
[admin@localhost ~]$ mount
[admin@localhost ~]$ df -h
    ...
    /dev/mapper/data-site1   2.0G  6.0M  1.8G   1% /mnt/site1
    /dev/mapper/data-site2   2.9G  9.0M  2.8G   1% /mnt/site2
[admin@localhost ~]$ cat /etc/fstab
    ...
    /dev/data/site1 /mnt/site1 ext4 defaults 0 0
    /dev/data/site2 /mnt/site2 ext4 defaults 0 0
[admin@localhost ~]$ sudo umount /mnt/site1
[admin@localhost ~]$ sudo umount /mnt/site2
[admin@localhost ~]$ sudo mount -av
    ...
    /mnt/site1               : successfully mounted
    ...
    /mnt/site2               : successfully mounted
```

---

## <u>*I. Setup serveur Web*</u>

Installation de nginx.

```
[admin@localhost ~]$ sudo yum install epel-release -y
[admin@localhost ~]$ sudo yum install nginx -y
```

Création des fichiers index.html dans site1 et site2.

```
[admin@localhost ~]$ echo "<h1>Hello world 1</h1>"|sudo tee -a /mnt/site1/index.html
    <h1>Hello world 1</h1>
[admin@localhost ~]$ echo "<h1>Hello world 2</h1>"|sudo tee -a /mnt/site2/index.html
    <h1>Hello world 2</h1>
```

Création du certificat ssl pour le https.

```
[admin@localhost ~]$ sudo mkdir /etc/nginx/ssl
[admin@localhost ~]$ sudo openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.crt
    Generating a 2048 bit RSA private key
    ....................................+++
    ..................................................+++
    writing new private key to '/etc/nginx/ssl/server.key'
    ...
```

Création d'un utilisateur et attribution des droits pour nginx.

```
[admin@localhost ~]$ sudo useradd web
[admin@localhost ~]$ sudo usermod -G web nginx
[admin@localhost ~]$ sudo chown -R web:web /mnt/site1
[admin@localhost ~]$ sudo chown -R web:web /mnt/site2
[admin@localhost ~]$ sudo ls -al /mnt/site1
    total 24
    dr-x------. 3 web  web   4096 Sep 28 14:00 .
    drwxr-xr-x. 4 root root    32 Sep 27 22:36 ..
    -r-x------. 1 web  web     23 Sep 28 14:03 index.html
    dr-x------. 2 web  web  16384 Sep 27 22:34 lost+found
[admin@localhost ~]$ sudo ls -al /mnt/site2
    total 24
    dr-x------. 3 web  web   4096 Sep 28 14:06 .
    drwxr-xr-x. 4 root root    32 Sep 27 22:36 ..
    -r-x------. 1 web  web     23 Sep 28 14:06 index.html
    dr-x------. 2 web  web  16384 Sep 27 22:34 lost+found
```

Configuration de Nginx.

```
[admin@localhost ~]$ sudo cat /etc/nginx/nginx.conf
    worker_processes 1;
    error_log /var/log/nginx/error.log;
    events {
        worker_connections 1024;
    }

    pid /run/nginx.pid;
    user web;

    http {
        server {
            listen 80;
            server_name node1.tp1.b2;
            return 301 https://$host$request_uri;
        }

    server {
            listen 443 ssl;
            server_name node1.tp1.b2;

            ssl_certificate /etc/nginx/ssl/server.crt;
            ssl_certificate_key /etc/nginx/ssl/server.key;

            location / {
                return 301 /site1;
            }

            location /site1 {
                alias /mnt/site1;
            }

            location /site2 {
                alias /mnt/site2;
            }
        }
    }
```

Sur la deuxième vm.

```
[admin@node2 ~]$ curl -Lk node1/site1
    <h1>Hello world 1</h1>
[admin@node2 ~]$ curl -Lk node1/site2
    <h1>Hello world 2</h1>
```

---

## <u>*II. Script de sauvegarde*</u>

### <u>*Script*</u>

Création de l'utilisateur backup et ajout dans le groupe web.

```
[admin@localhost opt]$ useradd backup
[admin@localhost opt]$ usermod -g web backup
```

On donne les droits à backup sur le script et le dossier backup.

```
[admin@localhost opt]$ ls -al /opt/
total 20
drwxr-xr-x.  3 root   root    89 Sep 28 22:26 .
dr-xr-xr-x. 17 root   root   224 Sep 27 21:33 ..
drwxr--r--.  3 backup root    19 Sep 28 22:50 backup
-rwxr--r--.  1 backup root  1358 Sep 28 23:13 tp1_backup.sh
-rwx------.  1 root   root   365 Sep 28 18:00 tp1_backup.sh~
-rw-------.  1 root   root 12288 Sep 28 18:01 .tp1_backup.sh.swp
```

Script de sauvegarde.

```
#!/bin/bash
# Thomas
# 28/09/2020
# Script de backup avec une limite de 7 backups

target_dir="${1}"
target_path="$(echo "${target_dir%/}" | awk -F "/" 'NF>1{print $NF}')"

date="$(date +%Y%m%d_%H%M%S)"
backup_name="${target_path}_${date}"
backup_dir="/opt/backup"
backup_path="${backup_dir}/${target_path}/${backup_name}.tar.gz"

backup_useruid="1002"
max_backup_number=7

if [[ $UID -ne ${backup_useruid} ]]
then
    echo "Ce script doit être éxecuté avec l'utilisateur backup" >&2
    exit 1
fi

if [[ ! -d "${target_dir}" ]]
then
    echo "Le dossier spécifié n'existe pas !" >&2
    exit 1
fi

backup_folder ()
{
    if [[ ! -d "${backup_dir}/${target_path}" ]]
    then
        mkdir "${backup_dir}/${target_path}"
    fi

    tar -czvf \
        ${backup_path} \
        ${target_dir} \
        1> /dev/null \
        2> /dev/null

    if [[ $(echo $?) -ne 0 ]]
    then
        echo "Une erreur est survenue lors de la compréssion" >&2
        exit 1
    else
        echo "La compréssion à réussi dans ${backup_dir}/${target_path}" >&1
    fi
}

delete_outdated_backup ()
{
    if [[ $(ls "${backup_dir}/${target_path}" | wc -l) -gt max_backup_number ]]
    then
        oldest_file=$(ls -t "${backup_dir}/${target_path}" | tail -1)
        rm -rf "${backup_dir}/${target_path}/${oldest_file}"
    fi
}

backup_folder
delete_outdated_backup
```

### <u>*Crontab*</u>

Création de la crontab.

```
[backup@localhost ~]$ crontab -l
*/1 * * * * /opt/tp1_backup.sh /mnt/site1
*/1 * * * * /opt/tp1_backup.sh /mnt/site2
```

### <u>*Restauration*</u>

Echec de ma part.

---

## <u>*III. Monitoring, alerting*</u>

### <u>*Installation*</u>

```
[admin@localhost ~]$ bash <(curl -Ss https://my-netdata.io/kickstart.sh)
```

Ouverture du port 19999 pour voir netdata sur le navigateur.

```
[admin@localhost ~]$ sudo firewall-cmd --add-port=19999/tcp --permanent
    success
[admin@localhost ~]$ sudo firewall-cmd --reload
    success
```

En allant sur 192.168.1.11:19999 on voit bien la page de netdata, plus qu'a configurer les notifications discord.

```
[admin@localhost ~]$ sudo /etc/netdata/edit-config health_alarm_notify.conf
    Editing '/etc/netdata/health_alarm_notify.conf' ...
```

Dans le health_alarm_notify on ajoute notre lien de webhook discord et on définié les envoie sur alarms et systems.

Après un peu de temps j'ai reçu un message sur mon salon discord.

---