#!/bin/bash

clear
WHOAMI=`whoami`
SU="root"
if [ "$WHOAMI" = "$SU" ]; then
    echo "deb http://ftp.ubuntu.com/ubuntu wily main restricted universe multiverse" > /etc/apt/sources.list
    echo "deb http://ftp.ubuntu.com/ubuntu wily-updates main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb http://ftp.ubuntu.com/ubuntu wily-backports main restricted universe multiverse" >> /etc/apt/sources.list
    echo -n "Indirizzo MAC (in formato 00:00:00:00:00:00) del PC di gestione?: "
    read MAC
    echo
    while [[ ! "$MAC" =~ ^([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}$ ]]
    do
        clear
        echo -n "L'indirizzo MAC e' sbagliato, inserici di nuovo: "
        read MAC
    done
    echo -n "Username per GIT?: "
    read -s USERGIT
    echo
    echo -n "Password per GIT?: "
    read -s PASSGIT
    apt-get update
    apt-get -y -f dist-upgrade
    cd /usr/local/src
    git clone http://$USERGIT:$PASSGIT@aron.ctimeapps.it/tony/aron-tools.git
    cd /usr/local/src/aron-tools
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install python-mysqldb python-django python-pip python-crypto firehol apache2 apache2-data apache2-bin \
                       apache2-utils pwgen sshpass libltdl7 liblua5.1-0 libmnl0 libnetfilter-conntrack3 squid-langpack \
                       ssl-cert libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libdbi-perl \
                       libapache2-mod-wsgi isc-dhcp-server libsodium-dev sudo hdparm ntp python-bcrypt mrtg snmpd
    MYSQLPASS=`pwgen -s 32 -n 1`
    echo
    ARONPASS=`pwgen -s 32 -n 1`
    echo
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQLPASS"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQLPASS"
    apt-get -y install mysql-server
    cd /usr/local/src
    git clone http://$USERGIT:$PASSGIT@aron.ctimeapps.it/tony/aron-web.git
    pip install singlemodeladmin
    pip install django-sizefield
    pip install libnacl
    pip install base58
    pip install iptools
    pip install pymysql
    git clone https://github.com/darklow/django-suit
    cd /usr/local/src/django-suit
    python setup.py install
    echo $MAC > /etc/firehol/mac_allow
    echo "www-data ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo "support ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
    cd /usr/local/src/aron-web
    git checkout aron-proxy
    mysql -u root -h localhost --password=$MYSQLPASS -e "CREATE DATABASE aron;"
    mysql -u root -h localhost --password=$MYSQLPASS -e "GRANT ALL PRIVILEGES ON aron.* TO 'aron'@'localhost' IDENTIFIED BY '$ARONPASS';"
    mysql -u root -h localhost --password=$MYSQLPASS -e "FLUSH PRIVILEGES;"
    sed -i "s/CHANGEMAC/$MAC/g" /usr/local/src/aron-web/fixtures/init.sql
    mysql -u aron -h localhost --database=aron --password=$ARONPASS < /usr/local/src/aron-web/fixtures/init.sql
    mv /usr/local/src/aron-tools/fixtures/config.py /usr/local/lib/python2.7/dist-packages/django_suit-0.2.18-py2.7.egg/suit/config.py
    mv /usr/local/src/aron-tools/fixtures/base.html /usr/local/lib/python2.7/dist-packages/django_suit-0.2.18-py2.7.egg/suit/templates/admin/base.html
    mv /usr/local/src/aron-tools/fixtures/aron.conf /etc/apache2/sites-available/000-default.conf
    dpkg -i /usr/local/src/aron-tools/fixtures/libecap3-dev_1.0.1-3_amd64.deb
    dpkg -i /usr/local/src/aron-tools/fixtures/libecap3_1.0.1-3_amd64.deb
    dpkg -i /usr/local/src/aron-tools/fixtures/squid-common_3.5.15-1_all.deb
    dpkg -i /usr/local/src/aron-tools/fixtures/squid-cgi_3.5.15-1_amd64.deb
    dpkg -i /usr/local/src/aron-tools/fixtures/squid-purge_3.5.15-1_amd64.deb
    dpkg -i /usr/local/src/aron-tools/fixtures/squid_3.5.15-1_amd64.deb
    dpkg -i /usr/local/src/aron-tools/fixtures/squid-dbg_3.5.15-1_amd64.deb
    /etc/init.d/squid stop
    rm -rfv /var/cache/squid/
    rm -f /etc/squid/squid.conf
    mkdir /var/cache/squid
    chown proxy:proxy /var/cache/squid -R
    mv /usr/local/src/aron-tools/fixtures/squid.conf /etc/squid/
    mv /usr/local/src/aron-tools/fixtures/url_patterns /etc/squid/
    mv -f /usr/local/src/aron-tools/fixtures/log_db_daemon /usr/lib/squid/log_db_daemon
    chmod 755 /usr/lib/squid/log_db_daemon
    mv /usr/local/src/aron-tools/fixtures/aron-proxy.pem /etc/squid/
    mv /usr/local/src/aron-tools/fixtures/aron-proxy.der /usr/local/src/aron-web/static/
    /usr/lib/squid/ssl_crtd -c -s /var/lib/ssl_db/
    chown proxy:proxy /var/lib/ssl_db/ -R
    rm -rfv /usr/share/squid/errors/Italian/*
    cp -vf /usr/local/src/aron-tools/fixtures/it/* /usr/share/squid/errors/Italian/
    eth0=`ip -o link show | awk '{print $2, $9}' | egrep -v lo | cut -d":" -f 1 | sed -n 1p`
    eth1=`ip -o link show | awk '{print $2, $9}' | egrep -v lo | cut -d":" -f 1 | sed -n 2p`
    eth2=`ip -o link show | awk '{print $2, $9}' | egrep -v lo | cut -d":" -f 1 | sed -n 3p`
    eth3=`ip -o link show | awk '{print $2, $9}' | egrep -v lo | cut -d":" -f 1 | sed -n 4p`
    cat > /etc/network/interfaces << EOF
auto lo $eth0 $eth1 $eth2 $eth3
iface lo inet loopback

iface $eth0 inet dhcp

iface $eth1 inet static
	address 192.168.50.1
	netmask 255.255.255.0
	network 192.168.50.0

iface $eth2 inet static
	address 192.168.60.1
	netmask 255.255.255.0
	network 192.168.60.0

iface $eth3 inet static
	address 192.168.70.1
	netmask 255.255.255.0
	network 192.168.70.0
EOF
    cat > /etc/firehol/firehol.conf << EOF
# Firewall config

version 6
LAN="10.0.0.0/8 172.16.0.0/16 192.168.0.0/16"

ipv4 transparent_proxy 80 3128 "root proxy" inface $eth1
ipv4 transparent_proxy 80 3128 "root proxy" inface $eth2
ipv4 transparent_proxy 80 3128 "root proxy" inface $eth3

FIREHOL_LOG_LEVEL=7
interface4 $eth0 ethernet
    UNMATCHED_INPUT_POLICY=DROP
    UNMATCHED_OUTPUT_POLICY=DROP
    UNMATCHED_FORWARD_POLICY=DROP
    FIREHOL_LOG_FREQUENCY="1/second"
    FIREHOL_LOG_BURST="1"
    policy drop
    protection strong 5/sec 5
    ipv4 server ident reject with tcp-reset
    ipv4 server "icmp ssh" accept
    ipv4 client all accept

interface4 $eth1 lan src "\${LAN}"
    policy accept
    ipv4 server all accept
    ipv4 client all accept

interface4 $eth2 segretaria src "\${LAN}"
    policy accept
    ipv4 server all accept
    ipv4 client all accept

interface4 $eth3 discovery src "\${LAN}"
    policy accept
    ipv4 server all accept
    ipv4 client all accept

router4 lan-1-inet inface $eth1 outface $eth0
    masquerade
    route4 all accept

router4 lan-2-inet inface $eth2 outface $eth0
    masquerade
    route4 all accept

router4 lan-3-inet inface $eth3 outface $eth0
    masquerade
    route4 all accept
EOF
    cat > /etc/dhcp/dhcpd.conf << EOF
ddns-update-style none;
authoritative;
option domain-name "aron.local";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 7200;
max-lease-time 7200;
log-facility local7;

subnet 192.168.50.0 netmask 255.255.255.0 {
	interface $eth1;
	range 192.168.50.10 192.168.50.254;
	option routers 192.168.50.1;
}
subnet 192.168.60.0 netmask 255.255.255.0 {
	interface $eth2;
	range 192.168.60.10 192.168.60.254;
	option routers 192.168.60.1;
}
subnet 192.168.70.0 netmask 255.255.255.0 {
	interface $eth3;
	range 192.168.70.10 192.168.70.254;
	option routers 192.168.70.1;
}
EOF
    mv /usr/local/src/aron-tools/fixtures/logfile-daemon_mysql.pl /usr/lib/squid/
    mv /usr/local/src/aron-tools/fixtures/snmpd.conf /etc/snmpd/
    tar zvfx /usr/local/src/aron-tools/fixtures/bigblacklist.tar.gz -C /etc/squid/
    sed -i 's/NO/YES/g' /etc/default/firehol
    sed -i "s/CHANGE/$ARONPASS/g" /usr/local/src/aron-web/web/settings.py
    sed -i "s/CHANGE_ETH0/$eth0/g" /usr/local/src/aron-web/fixtures/init.sql
    sed -i "s/CHANGE_ETH1/$eth1/g" /usr/local/src/aron-web/fixtures/init.sql
    sed -i "s/CHANGE_ETH2/$eth2/g" /usr/local/src/aron-web/fixtures/init.sql
    sed -i "s/CHANGE_ETH3/$eth3/g" /usr/local/src/aron-web/fixtures/init.sql
    sed -i 's/80/8088/g' /etc/apache2/ports.conf /etc/apache2/sites-available/000-default.conf
    rm -rfv /usr/local/src/django-suit
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    echo "127.0.0.1        localhost" > /etc/hosts
    echo "192.168.50.1      aron" >> /etc/hosts
    echo "192.168.50.1" > /etc/squid/aron_server
    echo "192.168.60.1" >> /etc/squid/aron_server
    echo "192.168.70.1" >> /etc/squid/aron_server
    echo "aron" > /etc/hostname
    touch /etc/squid/black_domain
    echo "#!/bin/sh -e" > /etc/rc.local
    echo "myisamchk -r /var/lib/mysql/aron/aron_logs" >> /etc/rc.local
    echo "chmod 666 /etc/squid/squid.conf" >> /etc/rc.local
    echo "chmod 666 /etc/firehol/mac_allow" >> /etc/rc.local
    echo "chmod 666 /etc/network/interfaces" >> /etc/rc.local
    echo "chmod 666 /etc/squid/aron_server" >> /etc/rc.local
    echo "chmod 666 /etc/resolv.conf" >> /etc/rc.local
    echo "chmod 666 /run/resolvconf/resolv.conf" >> /etc/rc.local
    echo "chmod 666 /var/log/squid/cache.log" >> /etc/rc.local
    echo "chmod 666 /etc/dhcp/dhcpd.conf" >> /etc/rc.local
    echo "chmod 666 /etc/hostname" >> /etc/rc.local
    echo "chmod 666 /var/log/syslog" >> /etc/rc.local
    echo "chmod 666 /etc/mrtg.cfg" >> /etc/rc.local
    echo "chmod 666 /etc/squid/black_domain" >> /etc/rc.local
    echo "sysctl -w net.core.rmem_max=8388608" >> /etc/rc.local
    echo "sysctl -w net.core.wmem_max=8388608" >> /etc/rc.local
    echo "sysctl -w net.core.rmem_default=65536" >> /etc/rc.local
    echo "sysctl -w net.core.wmem_default=65536" >> /etc/rc.local
    echo "sysctl -w net.ipv4.tcp_rmem='4096 87380 8388608'" >> /etc/rc.local
    echo "sysctl -w net.ipv4.tcp_wmem='4096 65536 8388608'" >> /etc/rc.local
    echo "sysctl -w net.ipv4.tcp_mem='8388608 8388608 8388608'" >> /etc/rc.local
    echo "sysctl -w net.ipv4.route.flush=1" >> /etc/rc.local
    echo "exit 0" >> /etc/rc.local
    chmod +x /etc/rc.local
    find /etc/squid/blacklists/ -type d -exec chmod 755 {} \;
    find /etc/squid/blacklists/ -type f -exec chmod 666 {} \;
    clear
    adduser support --quiet --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --home /usr/local/src/aron-web/web/ --disabled-password --shell /usr/local/src/aron-web/web/support.py
    echo "support:support" | chpasswd
    adduser support www-data
    chown -R support:support /usr/local/src/aron-web/web/npyscreen/ /usr/local/src/aron-web/web/support.py
    echo "Making cache directory ... after finish the system will be rebooted"
    rm -rfv /usr/local/src/aron-tools
    rm -fv /usr/local/src/aron-web/fixtures/init.sql
    /usr/sbin/squid -z &
    while true;
      do
        COUNT=`ls -lh /var/cache/squid | wc -l`
        if [ $COUNT -eq 257 ];
          then
            clear;
            echo "Cache directory Done!";
            echo "Rebooting system in 3 seconds";
            sleep 3;
            reboot;
        fi
    done
else
    echo "Errore: Devi essere root prima per eseguire questo script"
fi
