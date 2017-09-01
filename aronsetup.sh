#!/bin/bash

clear
WHOAMI=`whoami`
USERGIT="foo"
PASSGIT="bar"
# SIZE NUMBER IS ON Gb
SIZE="2"
HOSTMAIL="server.smtp.tld"
EMAILUSER="foo"
EPASSWORD="bar"
SENDER="no-reply@domain.tld"
SU="root"
STEP=36
if [ "$WHOAMI" = "$SU" ]; then
    clear
    echo "Aron Proxy installer is running..."
    sleep 1
    apt-get update
    apt-get install bc
    PERCENT=`echo "( 1 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Inserting sources packages into system to update/upgrade system"
    sleep 1
    echo "deb http://ftp.ubuntu.com/ubuntu zesty main restricted universe multiverse" > /etc/apt/sources.list
    echo "deb http://ftp.ubuntu.com/ubuntu zesty-updates main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb http://ftp.ubuntu.com/ubuntu zesty-backports main restricted universe multiverse" >> /etc/apt/sources.list
    clear
    PERCENT=`echo "( 2 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Excuting update system"
    sleep 1
    apt-get update
    clear
    PERCENT=`echo "( 3 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Excuting upgrade system"
    sleep 1
    apt-get -y -f dist-upgrade
    export DEBIAN_FRONTEND=noninteractive
    clear
    PERCENT=`echo "( 4 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Installing packages required"
    sleep 1
    apt-get -y install python-mysqldb python-django python-pip python-crypto firehol apache2 apache2-data apache2-bin apache2-utils pwgen sshpass libltdl7 liblua5.1-0 libmnl0 libnetfilter-conntrack3 squid-langpack ssl-cert libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libdbi-perl snmp-mibs-downloader libapache2-mod-wsgi isc-dhcp-server libsodium-dev sudo hdparm ntp python-bcrypt mrtg snmpd snmp-mibs-downloader python-dev libdbd-mysql-perl
    clear
    PERCENT=`echo "( 5 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Installing python modules"
    sleep 1
    pip install singlemodeladmin
    pip install django-sizefield
    pip install libnacl
    pip install base58
    pip install iptools
    pip install pymysql
    pip install netifaces
    clear
    PERCENT=`echo "( 6 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Generating random password"
    sleep 1
    MYSQLPASS=`pwgen -s 32 -n 1`
    echo
    ARONPASS=`pwgen -s 32 -n 1`
    echo
    clear
    PERCENT=`echo "( 7 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Installing MySQL database"
    sleep 1
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQLPASS"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQLPASS"
    apt-get -y install mysql-server
    clear
    PERCENT=`echo "( 8 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Installing Proxy"
    sleep 1
    dpkg -i /usr/local/src/aron-install/fixtures/libecap3_1.0.1-3_amd64.deb
    dpkg -i /usr/local/src/aron-install/fixtures/libecap3-dev_1.0.1-3_amd64.deb
    dpkg -i /usr/local/src/aron-install/fixtures/squid-common_3.5.15-1_all.deb
    dpkg -i /usr/local/src/aron-install/fixtures/squid-cgi_3.5.15-1_amd64.deb
    dpkg -i /usr/local/src/aron-install/fixtures/squid-purge_3.5.15-1_amd64.deb
    dpkg -i /usr/local/src/aron-install/fixtures/squid_3.5.15-1_amd64.deb
    dpkg -i /usr/local/src/aron-install/fixtures/squid-dbg_3.5.15-1_amd64.deb
    dpkg -i /usr/local/src/aron-install/fixtures/squidclient_3.5.23-1ubuntu1_amd64.deb
    clear
    PERCENT=`echo "( 9 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Stopping Proxy"
    sleep 1
    /etc/init.d/squid stop
    clear
    PERCENT=`echo "( 10 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Removing software before"
    sleep 1
    rm -rfv /usr/local/src/aron-web/
    clear
    PERCENT=`echo "( 11 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Setting users passwords "
    sleep 1
    echo "support:support" | chpasswd
    echo "aron:$ARONPASS" | chpasswd
    adduser support www-data
    echo "www-data ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo "support ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
    clear
    PERCENT=`echo "( 12 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Cloning django project theme "
    sleep 1
    git clone https://github.com/darklow/django-suit /tmp/django-suit
    cd /tmp/django-suit
    clear
    PERCENT=`echo "( 13 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Installing django project theme"
    sleep 1
    python setup.py install
    clear
    PERCENT=`echo "( 14 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Installing Aron Proxy Code"
    sleep 1
    git clone http://$USERGIT:$PASSGIT@github.com/emper0r/aron-proxy.git /usr/local/src/aron-web
    cd /usr/local/src/aron-web
    clear
    PERCENT=`echo "( 15 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Adding User -SUPPORT- "
    /usr/sbin/adduser support --gecos ",,," --home /usr/local/src/aron-web/web/ --disabled-password --shell /usr/local/src/aron-web/web/support.py
    sleep 1
    clear
    PERCENT=`echo "( 16 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Creating Aron Database and settings permisions"
    sleep 1
    mysql -u root -h localhost --password=$MYSQLPASS -e "CREATE DATABASE aron;"
    sleep 1
    mysql -u root -h localhost --password=$MYSQLPASS -e "GRANT ALL PRIVILEGES ON aron.* TO 'aron'@'localhost' IDENTIFIED BY '$ARONPASS';"
    sleep 1
    mysql -u root -h localhost --password=$MYSQLPASS -e "FLUSH PRIVILEGES;"
    sleep 1
    clear
    PERCENT=`echo "( 17 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Copying files required for django theme"
    sleep 1
    mv /usr/local/src/aron-install/fixtures/config.py /usr/local/lib/python2.7/dist-packages/django_suit-0.2.25-py2.7.egg/suit/config.py
    mv /usr/local/src/aron-install/fixtures/base.html /usr/local/lib/python2.7/dist-packages/django_suit-0.2.25-py2.7.egg/suit/templates/admin/base.html
    clear
    PERCENT=`echo "( 18 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Copying virtualhost"
    sleep 1
    mv /usr/local/src/aron-install/fixtures/aron.conf /etc/apache2/sites-available/000-default.conf
    clear
    PERCENT=`echo "( 19 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Preparing Proxy settings"
    sleep 1
    rm -f /etc/squid/squid.conf
    CACHESIZE=$(($SIZE * 1024))
    sed -i "s/CHANGE/$CACHESIZE/g" /usr/local/src/aron-web/Proxy/prx_wcf.py
    sed -i "s/CHANGE/$CACHESIZE/g" /usr/local/src/aron-install/fixtures/squid.conf
    mv /usr/local/src/aron-install/fixtures/squid.conf /etc/squid/
    mv /usr/local/src/aron-install/fixtures/url_patterns /etc/squid/
    mv -f /usr/local/src/aron-install/fixtures/log_db_daemon /usr/lib/squid/log_db_daemon
    chmod 755 /usr/lib/squid/log_db_daemon
    mv /usr/local/src/aron-install/fixtures/aron-proxy.pem /etc/squid/
    mv /usr/local/src/aron-install/fixtures/aron-proxy.der /usr/local/src/aron-web/static/
    echo "192.168.50.1" > /etc/squid/aron_server
    echo "$HOSTNAME" > /etc/hostname
    touch /etc/squid/black_domain
    echo "QdFeP+rqUADlFrOHdOxyvJrlcB/9IPG+uqXidQUbgAYgMqktGm3GBYRlQwfFRT9RA/dmlhhnUgf5nev++OgvN554YKGtiIxPOzvj5nimUuqzlggmsYzfVWnz3MqQukwsrrHiN8GRHEtQXG9bPSO7zXGxgtlLknUkkA+nwjK/vg0PcPa8jZg2kyotohhAXL3UjItkVczCdECwR5J4Fyrulq8a0BNBM+ueGaQx43Sc87X9zaKe96TbPveAhuqF0ca6mj8BSCaHYUwG50kPXtis+ytQZDycLapKnAZr1FS+SzwwtZF7t+sTiEBZG5Pr18dwPXibm9hRH3D0in3+VyLKtlA67Vf7hauncwdMswSPLkdoga6t4h51Y6PXh0LTZR7b9SB+/Ct42rePYuSoTpE5pbV29SCyDi8wN7ybjin9WrRHxDF90tt4Z5KgtQwm56f0MAZWb3hVwj4r7HkueqAFNj1kOQI5in6350gm1omRCN5LhHHrW+4Da3Yfuxo/Gh9k5n+k1VVClxfWskGFw7MxoEroXpU5xn28RScWIMD0AII2z/bP0gB+2Yliqwc13tmNHcvMwWzPiWN3hNhidtI4IEZd5NsNNib033oVnqN813TbSjl4aRwLKmeSEk4l+SCZVQOHPBQMcoXB0Atufp3XyipQHPNPpgRNbKEYlpVeTlrgvnD5RsKCjN06HdXFTRQXtPdOiCIwqXPfI70BtYULfSKkDM+ujYD010SjloS3U8PLC2naWs4r/xcmJxaZArsnlr4N7TLQLRmf9UdDlGk0AoHOy+V55lYHAULXmMbIRr1jIMcKEklubiDqKGCAUEkBDeTiIk/h08arV/FYLtiWIg9n/lhp5+31CJG/92CeP3Iv+tS/8KNYyKblFppPqlZ439QcoALVPpYDYFqZ+keI/65HKl7UB7q+yofylSaOkVA=" > /etc/squid/squid.conf.aron
    /usr/lib/squid/ssl_crtd -c -s /var/lib/ssl_db/
    rm -fv /var/log/squid/access.log
    rm -fv /var/log/squid/cache.log
    touch /var/log/squid/access.log
    touch /var/log/squid/cache.log
    touch /etc/firehol/mac_allow
    chown proxy:proxy /var/lib/ssl_db/ -R
    chown proxy:proxy /var/log/squid/access.log
    chown proxy:proxy /var/log/squid/cache.log
    chmod 666 /var/log/squid/cache.log
    rm -rfv /var/cache/squid
    mkdir -p /var/cache/squid
    chown proxy:proxy /var/cache/squid
    clear
    PERCENT=`echo "( 20 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Creating Cache"
    sleep 1
    /usr/sbin/squid -z &
    chown proxy.proxy /var/cache/squid -R
    clear
    PERCENT=`echo "( 21 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Copying Italian error files"
    sleep 1
    rm -rfv /usr/share/squid/errors/Italian/*
    cp -vf /usr/local/src/aron-install/fixtures/it/* /usr/share/squid/errors/Italian/
    clear
    PERCENT=`echo "( 22 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Taking ethernet interfaces info"
    sleep 1
    eth0=`ip -o link show | awk '{print $2, $9}' | egrep -v lo | cut -d":" -f 1 | sed -n 1p`
    eth1=`ip -o link show | awk '{print $2, $9}' | egrep -v lo | cut -d":" -f 1 | sed -n 2p`
    ipeth0=`ifconfig $eth0 | egrep -i "inet" | awk '{print $2}' | head -1`
    clear
    PERCENT=`echo "( 23 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Creating network file"
    sleep 1
    cat > /etc/network/interfaces << EOF
auto lo $eth0 $eth1
iface lo inet loopback

iface $eth0 inet dhcp

iface $eth1 inet static
	address 192.168.50.1
	netmask 255.255.255.0
	network 192.168.50.0
EOF
    clear
    PERCENT=`echo "( 24 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Creating firewall file"
    sleep 1
    cat > /etc/firehol/firehol.conf << EOF
# Firewall config

version 6
LAN="10.0.0.0/8 172.16.0.0/16 192.168.0.0/16"

ipv4 transparent_proxy 80 3128 "root proxy" inface $eth1

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

interface4 $eth1 lan-1 src "\${LAN}"
    policy accept
    ipv4 server all accept
    ipv4 client all accept

router4 lan-1-inet inface $eth1 outface $eth0
    masquerade
    route4 all accept
EOF
    clear
    PERCENT=`echo "( 25 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Creating dhcp file"
    sleep 1
    cat > /etc/dhcp/dhcpd.conf << EOF
ddns-update-style none;
authoritative;
option domain-name "$HOSTNAME";
option domain-name-servers 8.8.8.8, 8.8.4.4;
default-lease-time 7200;
max-lease-time 7200;
log-facility local7;

subnet 192.168.50.0 netmask 255.255.255.0 {
	interface $eth1;
	range 192.168.50.10 192.168.50.254;
	option routers 192.168.50.1;
}
EOF
    clear
    PERCENT=`echo "( 26 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Creating graphic file"
    sleep 1
    cat > /etc/mrtg.cfg << EOF
LoadMIBs: /usr/share/snmp/mibs/UCD-SNMP-MIB.txt
RunAsDaemon: Yes
Interval: 5
WorkDir: /usr/local/src/aron-web/static/dashboard/
Options[_]: growright, bits
EnableIPv6: no

Target[localhost_$eth0]: #$eth0:public@localhost:
SetEnv[localhost_$eth0]: MRTG_INT_IP="$ipeth0" MRTG_INT_DESCR="No-Description"
MaxBytes[localhost_$eth0]: 125000000
Title[localhost_$eth0]: Traffic Analysis for $eth0 -- $HOSTNAME

Target[localhost_$eth1]: #$eth1:public@localhost:
SetEnv[localhost_$eth1]: MRTG_INT_IP="192.168.50.1" MRTG_INT_DESCR="No-Description"
MaxBytes[localhost_$eth1]: 125000000
Title[localhost_$eth1]: Traffic Analysis for $eth1 -- $HOSTNAME
EOF
    clear
    PERCENT=`echo "( 27 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Setting SNMP"
    sleep 1
    sed -i 's/#rocommunity public  localhost/rocommunity public  localhost/g' /etc/snmp/snmpd.conf
    clear
    PERCENT=`echo "( 28 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Unzipped blacklist"
    sleep 1
    tar zfx /usr/local/src/aron-install/fixtures/bigblacklist.tar.gz -C /etc/squid/
    clear
    PERCENT=`echo "( 29 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Setting parameters into Aron Proxy Project"
    sleep 1
    sed -i 's/NO/YES/g' /etc/default/firehol
    sed -i "s/ARONPWD/$ARONPASS/g" /usr/local/src/aron-web/web/settings.py
    sed -i "s/SENDER/$SENDER/g" /usr/local/src/aron-web/web/settings.py
    sed -i "s/HOSTMAIL/$HOSTMAIL/g" /usr/local/src/aron-web/web/settings.py
    sed -i "s/EMAILUSER/$EMAILUSER/g" /usr/local/src/aron-web/web/settings.py
    sed -i "s/EPASSWORD/$EPASSWORD/g" /usr/local/src/aron-web/web/settings.py
    sed -i "s/CHANGE_ETH0/$eth0/g" /usr/local/src/aron-web/fixtures/init.sql
    sed -i "s/CHANGE_ETH1/$eth1/g" /usr/local/src/aron-web/fixtures/init.sql
    clear
    PERCENT=`echo "( 30 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Importing Aron schema into MySQL Database"
    sleep 1
    mysql -u aron -h localhost --database=aron --password=$ARONPASS < /usr/local/src/aron-web/fixtures/init.sql
    clear
    PERCENT=`echo "( 31 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Installing NGINX web server for error page"
    sleep 1
    /etc/init.d/apache2 stop
    apt-get install nginx-full -y
    /etc/init.d/nginx stop
    clear
    PERCENT=`echo "( 32 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Setting ports for web servers"
    sleep 1
    sed -i "s/80/8888/g" /etc/nginx.conf
    sed -i "s/80/8088/g" /etc/apache2/ports.conf
    sed -i "s/80/8088/g" /etc/apache2/sites-available/000-default.conf
    sed -i "s/80/8888/g" /etc/nginx/sites-available/default
    sed -i "s/APACHE_HOSTNAME/$HOSTNAME/g" /etc/apache2/sites-available/000-default.conf
    cp -v /usr/share/squid/errors/Italian/ERR_ACCESS_DENIED /var/www/html/index.html
    clear
    PERCENT=`echo "( 33 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Setting initial script"
    sleep 1
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    echo "127.0.0.1        localhost" > /etc/hosts
    echo "192.168.50.1      $HOSTNAME" >> /etc/hosts
    cat > /etc/rc.local << EOF
#!/bin/sh -e
chmod 666 /etc/squid/squid.conf.aron
chmod 666 /etc/firehol/mac_allow
chmod 666 /etc/firehol/firehol.conf
chmod 666 /etc/network/interfaces
chmod 666 /etc/squid/aron_server
chmod 666 /etc/resolv.conf
chmod 666 /run/resolvconf/resolv.conf
chmod 666 /var/log/squid/cache.log
chmod 666 /etc/dhcp/dhcpd.conf
chmod 666 /etc/hostname
chmod 666 /var/log/syslog
chmod 666 /etc/squid/black_domain
chmod 666 /etc/mrtg.cfg
env LANG=C /usr/bin/mrtg
myisamchk -r /var/lib/mysql/aron/aron_logs.MYI --force
/usr/local/src/aron-web/son-soff.py
chmod 666 /etc/squid/squid.conf
/etc/init.d/squid restart
rm -f /etc/squid/squid.conf
touch /etc/squid/squid.conf
chmod 666 /etc/squid/squid.conf
exit 0
EOF
    chmod +x /etc/rc.local
    clear
    PERCENT=`echo "( 34 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Setting file permissions"
    sleep 1
    find /etc/squid/blacklists/ -type d -exec chmod 755 {} \;
    find /etc/squid/blacklists/ -type f -exec chmod 666 {} \;
    chown www-data:www-data /usr/local/src/aron-web/ -R
    mkdir /usr/local/src/aron-web/web/.ssh
    touch /usr/local/src/aron-web/web/.ssh/known_hosts
    chown -R support.support /usr/local/src/aron-web/web/npyscreen/
    chown -R support.support /usr/local/src/aron-web/.ssh/
    chown support.support /usr/local/src/aron-web/web/support.py
    chmod +x /usr/local/src/aron-web/web/support.py
    chmod +x /usr/local/src/aron-web/son-soff.py
    clear
    PERCENT=`echo "( 35 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Deleting temporary files"
    sleep 1
    rm -fv /usr/local/src/aron-web/fixtures/init.sql
    rm -rfv /tmp/django-suit
    rm -rfv /usr/local/src/aron-install
    clear
    PERCENT=`echo "( 36 / $STEP * 100.0)" | bc -l | cut -d"." -f1`
    echo "$PERCENT% - Syncing file system and reboot"
    sleep 1
    sync
    reboot
else
    echo "Errore: Devi essere root prima per eseguire questo script"
fi
