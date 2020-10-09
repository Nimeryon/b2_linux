# <u>**TP3 : systemd**</u>

## <u>**I. Services systemd**</u>

### <u>**1. Intro**</u>

Afficher le nombre de services systemd dispos sur la machine
```bash
[vagrant@node1 ~]$ systemctl list-units  --type=service | wc -l
    42
```

Afficher le nombre de services systemd actifs et en cours d'exécution ("running") sur la machine
```bash
[vagrant@node1 ~]$ systemctl list-units --type=service | grep running | wc -l
    17
```

Afficher le nombre de services systemd qui ont échoué ("failed") ou qui sont inactifs ("exited") sur la machine
```bash
[vagrant@node1 ~]$ systemctl list-units --type=service | grep -E 'failed|exited' | wc -l
    17
```

Afficher la liste des services systemd qui démarrent automatiquement au boot ("enabled")
```bash
systemctl list-unit-files --type=service | grep enabled | wc -l
    32
```

### <u>**2. Analyse d'un service**</u>

```bash
[vagrant@node1 ~]$ systemctl cat nginx.service 
    # /usr/lib/systemd/system/nginx.service
    [Unit]
    Description=The nginx HTTP and reverse proxy server
    After=network.target remote-fs.target nss-lookup.target

    [Service]
    Type=forking
    PIDFile=/run/nginx.pid
    # Nginx will fail to start if /run/nginx.pid already exists but has the wrong
    # SELinux context. This might happen when running `nginx -t` from the cmdline.
    # https://bugzilla.redhat.com/show_bug.cgi?id=1268621
    ExecStartPre=/usr/bin/rm -f /run/nginx.pid
    ExecStartPre=/usr/sbin/nginx -t
    ExecStart=/usr/sbin/nginx
    ExecReload=/bin/kill -s HUP $MAINPID
    KillSignal=SIGQUIT
    TimeoutStopSec=5
    KillMode=process
    PrivateTmp=true

    [Install]
    WantedBy=multi-user.target
```

>- ExecStart : Commande éxécuté au démarrage du service
>- ExecStartPre : Commande éxécuté avant le démarrage du service
>- PIDFile : Prend un chemin dirigeant vers un  fichier PID du service
>- Type : Configure le type de démarrage du service ( simple, exec, forking, oneshot, dbus, notify, idle )
>- ExecReload : La commande à éffectuer pour redémarrer la configuration du service
>- Description : Description du service
>- After : Ordre de démmarage, le service placé dans after ne demarrera que aprés celui-ci

> Listez tous les services qui contiennent la ligne WantedBy=multi-user.target :
```bash
[vagrant@node1 ~]$ grep -r 'WantedBy=multi-user.target' /usr/lib/systemd/system
    /usr/lib/systemd/system/fstrim.timer:WantedBy=multi-user.target
    /usr/lib/systemd/system/machines.target:WantedBy=multi-user.target
    /usr/lib/systemd/system/remote-cryptsetup.target:WantedBy=multi-user.target
    /usr/lib/systemd/system/remote-fs.target:WantedBy=multi-user.target
    /usr/lib/systemd/system/rpcbind.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/rdisc.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/brandbot.path:WantedBy=multi-user.target
    /usr/lib/systemd/system/tcsd.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/sshd.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/rhel-configure.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/rsyslog.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/irqbalance.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/cpupower.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/crond.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/rpc-rquotad.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/wpa_supplicant.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/chrony-wait.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/chronyd.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/NetworkManager.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/ebtables.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/gssproxy.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/tuned.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/firewalld.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/nfs-client.target:WantedBy=multi-user.target
    /usr/lib/systemd/system/nfs-server.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/rsyncd.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/nginx.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/vmtoolsd.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/postfix.service:WantedBy=multi-user.target
    /usr/lib/systemd/system/auditd.service:WantedBy=multi-user.target
```

### <u>**3. Création d'un service**</u>

#### <u>**A. Serveur web**</u>
>
- Créez une unité de service qui lance un serveur web
    >[Service web](./system/units/ServerWeb.service)

Prouver qu'il est en cours de fonctionnement pour systemd
```
[vagrant@node1 ~]$ systemctl status ServerWeb
    ● ServerWeb.service - Serveur web tp3
    Loaded: loaded (/etc/systemd/system/ServerWeb.service; enabled; vendor preset: disabled)
    Active: active (running) since Fri 2020-10-09 14:21:53 UTC; 16s ago
    Process: 3482 ExecStartPre=/usr/bin/sudo /usr/bin/firewall-cmd --add-port=${PORT}/tcp (code=exited, status=0/SUCCESS)
    Main PID: 3489 (sudo)
    CGroup: /system.slice/ServerWeb.service
            ‣ 3489 /usr/bin/sudo /usr/bin/python3 -m http.server 1020
```

Faites en sorte que le service s'allume au démarrage de la machine
```
[vagrant@node1 ~]$ sudo systemctl enable ServerWeb
```

Prouver que le serveur web est bien fonctionnel ( Depuis l'host )
```
PS C:\Users\tauri> curl 192.168.3.11:1020

    StatusCode        : 200
    StatusDescription : OK
    Content           : <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
                        <html>
                        <head>
                        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
                        <title>Directory listing fo...
    RawContent        : HTTP/1.0 200 OK
                        Content-Length: 983
                        Content-Type: text/html; charset=utf-8
                        Date: Fri, 09 Oct 2020 14:23:51 GMT
                        Server: SimpleHTTP/0.6 Python/3.6.8

                        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//...
    Forms             : {}
    Headers           : {[Content-Length, 983], [Content-Type, text/html; charset=utf-8], [Date, Fri, 09 Oct 2020 14:23:51
                        GMT], [Server, SimpleHTTP/0.6 Python/3.6.8]}
    Images            : {}
    InputFields       : {}
    Links             : {@{innerHTML=bin@; innerText=bin@; outerHTML=<A href="bin/">bin@</A>; outerText=bin@; tagName=A;
                        href=bin/}, @{innerHTML=boot/; innerText=boot/; outerHTML=<A href="boot/">boot/</A>;
                        outerText=boot/; tagName=A; href=boot/}, @{innerHTML=dev/; innerText=dev/; outerHTML=<A
                        href="dev/">dev/</A>; outerText=dev/; tagName=A; href=dev/}, @{innerHTML=etc/; innerText=etc/;
                        outerHTML=<A href="etc/">etc/</A>; outerText=etc/; tagName=A; href=etc/}...}
    ParsedHtml        : mshtml.HTMLDocumentClass
    RawContentLength  : 983
```

#### <u>**B. Sauvegarde**</u>

- [Script éclaté en 3](./systemd/conf/)
- [Backup.service](./systemd/units/Backup.service)
- [Backup.timer](./systemd/units/Backup.timer)
-  Ecrire un fichier .timer systemd
```
[vagrant@node1 ~]$ systemctl list-timers
    NEXT                         LEFT       LAST PASSED UNIT                         ACTIVATES
    [...]
    Fri 2020-10-09 22:00:00 UTC  22min left n/a  n/a    Backup.timer    
```

---

## <u>**II. Autres features**</u>

### <u>**1. Gestion de boot**</u>

- Utilisez systemd-analyze plot pour récupérer une diagramme du boot, au format SVG
```
[vagrant@node1 ~]$ systemd-analyze plot > /tmp/plot.svg
```

Après analyse du fichier je détermine que les 3 services les plus lent à démarrer sont :
- sshd-keygen.service (1.532s)
- dev-sda1.device (1.512s)
- tuned.service (1.472s)

### <u>**2. Gestion de l'heure**</u>

- Déterminer votre fuseau horaire
```
[vagrant@node1 ~]$ timedatectl
    Local time: Fri 2020-10-09 22:07:57 UTC
    Universal time: Fri 2020-10-09 22:07:57 UTC
            RTC time: Fri 2020-10-09 22:07:55
        Time zone: UTC (UTC, +0000)
        NTP enabled: yes
    NTP synchronized: yes
    RTC in local TZ: no
        DST active: n/a
```

- Déterminer si vous êtes synchronisés avec un serveur NTP
```
[vagrant@node1 ~]$ timedatectl
    [...]
    NTP synchronized: yes
    [...]
```

- Changer le fuseau horaire
    - On détermine tout les fuseaux horaire disponible
    ```
    [vagrant@node1 ~]$ timedatectl list-timezones
        Africa/Abidjan
        Africa/Accra
        Africa/Addis_Ababa
        [...]
    ```
    - On change de fuseaux horaire
    ```
    [vagrant@node1 ~]$ sudo timedatectl set-timezone Africa/Accra
    ```
    - On vérifie le changement
    ```
    [vagrant@node1 ~]$ timedatectl
        Local time: Fri 2020-10-09 22:12:07 GMT
        Universal time: Fri 2020-10-09 22:12:07 UTC
                RTC time: Fri 2020-10-09 22:12:04
            Time zone: Africa/Accra (GMT, +0000)
            NTP enabled: yes
        NTP synchronized: yes
        RTC in local TZ: no
            DST active: n/a
    ```

### <u>**3. Gestion des noms et de la résolution de noms**</u>

- Déterminer votre hostname actuel
```
[vagrant@node1 ~]$ hostnamectl
    Static hostname: node1.tp3.b2
            Icon name: computer-vm
            Chassis: vm
            Machine ID: d1e68a3164f74323b14bd129c75a9350
            Boot ID: e6032480858a4a2c8f844c0e8407c9c3
        Virtualization: kvm
    Operating System: CentOS Linux 7 (Core)
        CPE OS Name: cpe:/o:centos:centos:7
                Kernel: Linux 3.10.0-1127.el7.x86_64
        Architecture: x86-64
```
    Le hostoname est node.tp3.b2

- Changer votre hostname
```
[vagrant@node1 ~]$ sudo hostnamectl set-hostname customnode1.tp3.b2
[vagrant@node1 ~]$ hostnamectl
    Static hostname: customnode1.tp3.b2
            Icon name: computer-vm
            Chassis: vm
            Machine ID: d1e68a3164f74323b14bd129c75a9350
            Boot ID: e6032480858a4a2c8f844c0e8407c9c3
        Virtualization: kvm
    Operating System: CentOS Linux 7 (Core)
        CPE OS Name: cpe:/o:centos:centos:7
                Kernel: Linux 3.10.0-1127.el7.x86_64
        Architecture: x86-64
```