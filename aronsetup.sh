#!/bin/bash

clear
WHOAMI=`whoami`
SU="root"
if [ "$WHOAMI" = "$SU" ]; then
    echo "deb http://it.archive.ubuntu.com/ubuntu wily main restricted universe multiverse" > /etc/apt/sources.list
    echo "deb http://it.archive.ubuntu.com/ubuntu wily-updates main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb http://it.archive.ubuntu.com/ubuntu wily-backports main restricted universe multiverse" >> /etc/apt/sources.list
    echo -n "Indirizzo MAC (in formato 00:00:00:00:00:00) del PC di gestione?: ";
    read MAC;
    echo
    while [[ ! "$MAC" =~ ^([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}$ ]]
    do
        clear
        echo -n "L'indirizzo MAC e' sbagliato, inserici di nuovo: ";
        read MAC;
    done
    echo -n "Username per GIT?: ";
    read -s USERGIT
    echo
    echo -n "Password per GIT?: ";
    read -s PASSGIT
    apt-get update;
    apt-get -y -f dist-upgrade;
    cd /usr/local/src;
    git clone http://$USERGIT:$PASSGIT@aron.ctimeapps.it/tony/aron-tools.git
    cd /usr/local/src/aron-tools
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install squid3 python-mysqldb python-django python-pip python-crypto firehol apache2 pwgen sshpass \
                       libapache2-mod-wsgi isc-dhcp-server libsodium-dev sudo hdparm ntp python-bcrypt mrtg snmpd;
    MYSQLPASS=`pwgen -s 32 -n 1`
    echo
    ARONPASS=`pwgen -s 32 -n 1`
    echo
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQLPASS"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQLPASS"
    apt-get -y install mysql-server
    cd /usr/local/src;
    git clone http://$USERGIT:$PASSGIT@aron.ctimeapps.it/tony/aron-web.git;
    pip install singlemodeladmin;
    pip install django-sizefield;
    pip install libnacl;
    pip install base58;
    pip install iptools;
    pip install django-tables2;
    pip install pymysql;
    git clone https://github.com/darklow/django-suit;
    cd /usr/local/src/django-suit;
    python setup.py install;
    echo $MAC > /etc/firehol/mac_allow;
    echo "www-data ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers;
    echo "support ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers;
    cd /usr/local/src/aron-web;
    git checkout aron-proxy;
    mysql -u root -h localhost --password=$MYSQLPASS -e "CREATE DATABASE aron;";
    mysql -u root -h localhost --password=$MYSQLPASS -e "GRANT ALL PRIVILEGES ON aron.* TO 'aron'@'localhost' IDENTIFIED BY '$ARONPASS';";
    mysql -u root -h localhost --password=$MYSQLPASS -e "FLUSH PRIVILEGES;";
    sed -i "s/CHANGEMAC/$MAC/g" /usr/local/src/aron-web/fixtures/init.sql
    mysql -u aron -h localhost --database=aron --password=$ARONPASS < /usr/local/src/aron-web/fixtures/init.sql;
    rm -f /usr/local/src/aron-web/fixtures/init.sql
    mv /usr/local/src/aron-tools/fixtures/config.py /usr/local/lib/python2.7/dist-packages/django_suit-0.2.15-py2.7.egg/suit/config.py
    mv /usr/local/src/aron-tools/fixtures/base.html /usr/local/lib/python2.7/dist-packages/django_suit-0.2.15-py2.7.egg/suit/templates/admin/base.html
    mv /usr/local/src/aron-tools/fixtures/aron.conf /etc/apache2/sites-available/000-default.conf;
    mv /usr/local/src/aron-tools/fixtures/squid.conf /etc/squid3/
    mv -f /usr/local/src/aron-tools/fixtures/log_db_daemon /usr/lib/squid3/log_db_daemon
    mv /usr/local/src/aron-tools/fixtures/interfaces /etc/network/interfaces
    mv /usr/local/src/aron-toosl/fixtures/dhcpd.conf /etc/dhcp/dhcpd.conf
    mv /usr/local/src/aron-tools/fixtures/logfile-daemon_mysql.pl /usr/lib/squid3/
    mv /usr/local/src/aron-tools/fixtures/firehol.conf /etc/firehol/
    mv /usr/local/src/aron-tools/fixtures/snmpd.conf /etc/snmpd/
    tar zvfx /usr/local/src/aron-tools/fixtures/bigblacklist.tar.gz -C /etc/squid3/
    sed -i 's/NO/YES/g' /etc/default/firehol
    sed -i "s/CHANGE/$ARONPASS/g" /usr/local/src/aron-web/web/settings.py
    sed -i 's/80/8088/g' /etc/apache2/ports.conf /etc/apache2/sites-available/000-default.conf
    mkdir /var/cache/squid3
    /etc/init.d/squid3 stop
    chown proxy:proxy /var/cache/squid3 -R
    cp /usr/local/src/aron-tools/fixtures/init-daemon-squid3 /etc/init.d/squid3
    rm -rfv /usr/local/src/aron-tools
    rm -rfv /usr/local/src/django-suit
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    echo "127.0.0.1        localhost" > /etc/hosts
    echo "192.168.0.1      aron" >> /etc/hosts
    echo "192.168.0.1" > /etc/squid3/aron_server
    echo "192.168.1.1" >> /etc/squid3/aron_server
    echo "192.168.2.1" >> /etc/squid3/aron_server
    echo "aron" > /etc/hostname
    touch /etc/squid3/black_domain
    echo "myisamchk -r /var/lib/mysql/aron/aron_logs" >> /etc/rc.local
    echo "chmod 666 /etc/squid3/squid.conf" >> /etc/rc.local
    echo "chmod 666 /etc/firehol/mac_allow" >> /etc/rc.local
    echo "chmod 666 /etc/network/interfaces" >> /etc/rc.local
    echo "chmod 666 /etc/squid3/aron_server" >> /etc/rc.local
    echo "chmod 666 /etc/resolv.conf"  >> /etc/rc.local
    echo "chmod 666 /run/resolvconf/resolv.conf" >> /etc/rc.local
    echo "chmod 666 /var/log/squid3/cache.log" >> /etc/rc.local
    echo "chmod 666 /etc/dhcp/dhcpd.conf" >> /etc/rc.local
    echo "chmod 666 /etc/hostname"  >> /etc/rc.local
    echo "chmod 666 /var/log/syslog"  >> /etc/rc.local
    echo "chmod 666 /etc/mrtg.cfg" >> /etc/rc.local
    echo "chmod 666 /etc/squid3/black_domain" >> /etc/rc.local
    chmod +x /etc/rc.local
    find /etc/squid3/blacklists/ -type d -exec chmod 755 {} \;
    find /etc/squid3/blacklists/ -type f -exec chmod 666 {} \;
    clear;
    adduser support --quiet --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --home /usr/local/src/aron-web/web/ --disabled-password --shell /usr/local/src/aron-web/web/support.py
    echo "support:support" | chpasswd
    adduser support www-data
    chown -R support:support /usr/local/src/aron-web/web/npyscreen/ /usr/local/src/aron-web/web/support.py
    echo "Making cache directory ... after finish the system will be rebooted"
    mv /usr/local/src/aron-toosl/fixtures/myCA.pem /etc/squid3/myCA.pem
    mv /usr/local/src/aron-toosl/fixtures/myCA.der /etc/squid3/myCA.der
    /usr/lib/squid3/ssl_crtd -c -s /var/lib/ssl_db/
    chown proxy:proxy /var/lib/ssl_db/ -R
    /usr/sbin/squid3 -z &
    while true;
      do
        COUNT=`ls -lh /var/cache/squid3 | wc -l`
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