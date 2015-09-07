#!/bin/bash

clear
WHOAMI=`whoami`
SU="root"
if [ "$WHOAMI" = "$SU" ]; then
    echo "deb http://it.archive.ubuntu.com/ubuntu vivid main restricted universe multiverse" > /etc/apt/sources.list
    echo "deb http://it.archive.ubuntu.com/ubuntu vivid-updates main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb http://it.archive.ubuntu.com/ubuntu vivid-backports main restricted universe multiverse" >> /etc/apt/sources.list
    echo -n "Password per installazione MySQL server?: ";
    read -s MYSQLPASS;
    echo
    echo -n  "Password per database aron?: ";
    read -s ARONPASS;
    echo
    echo -n "Username per GIT?: ";
    read -s USERGIT
    echo
    echo -n "Passowrd per GIT: ";
    read -s PASSGIT
    apt-get update;
    apt-get -y -f dist-upgrade;
    cd /usr/local/src;
    git clone http://$USERGIT:$PASSGIT@aron.ctimeapps.it/tony/aron-tools.git
    cd /usr/local/src/aron-tools
    apt-get -y install squid3 dansguardian python-mysqldb python-django python-pip python-crypto exim4-daemon-heavy dovecot-mysql firehol clamav-daemon git apache2 libapache2-mod-wsgi isc-dhcp-server libsodium-dev sudo hdparm ntp;
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
    git clone https://github.com/darklow/django-suit;
    cd /usr/local/src/django-suit;
    python setup.py install;
    touch /etc/squid3/mac_allow /etc/squid3/classes_allow;
    chmod 666 /etc/squid3/squid.conf \
	      /etc/squid3/mac_allow \
              /etc/squid3/classes_allow \
              /etc/network/interfaces \
              /var/log/squid3/cache.log \
              /etc/dansguardian/lists/bannedsitelist \
              /etc/dansguardian/lists/bannedurllist \
              /etc/dhcp/dhcpd.conf;
    mkdir -p /srv/vmail;
    useradd -r -m -U -s /bin/false -d /var/spool/vmail vmail;
    chown vmail:vmail -R /srv/vmail;
    echo "www-data ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers;
    cd /usr/local/src/aron-web;
    mysql -u root -h localhost --password=$MYSQLPASS -e "CREATE DATABASE aron;";
    mysql -u root -h localhost --password=$MYSQLPASS -e "GRANT ALL PRIVILEGES ON aron.* TO 'aron'@'localhost' IDENTIFIED BY '$ARONPASS';";
    mysql -u root -h localhost --password=$MYSQLPASS -e "FLUSH PRIVILEGES;";
    mysql -u aron -h localhost --database=aron --password=$ARONPASS < /usr/local/src/aron-web/fixtures/init.sql;
    mysql -u aron -h localhost --database=aron --password=$ARONPASS < /usr/local/src/aron-web/fixtures/init_2.sql;
    mv /usr/local/src/aron-tools/fixtures/config.py /usr/local/lib/python2.7/dist-packages/django_suit-0.2.14-py2.7.egg/suit/config.py
    mv /usr/local/src/aron-tools/fixtures/base.html /usr/local/lib/python2.7/dist-packages/django_suit-0.2.14-py2.7.egg/suit/templates/admin/base.html
    mv /usr/local/src/aron-tools/fixtures/aron.conf /etc/apache2/sites-available/;
    mv /usr/local/src/aron-tools/fixtures/dansguardian.conf /etc/dansguardian/
    mv /usr/local/src/aron-tools/fixtures/squid.conf /etc/squid3/
    mv /usr/local/src/aron-tools/fixtures/logfile-daemon_mysql.pl /usr/lib/squid3/
    mv /usr/local/src/aron-tools/fixtures/firehol.conf /etc/firehol/
    sed -i 's/NO/YES/g' /etc/default/firehol
    sed -i "s/CHANGE/$ARONPASS/g" /usr/lib/squid3/logfile-daemon_mysql.pl
    a2ensite aron.conf;
    /etc/init.d/apache2 restart;
    mkdir /var/cache/squid3
    /etc/init.d/squid3 stop
    chown proxy:proxy /var/cache/squid3 -R
    squid3 -z
    cp /usr/local/src/aron-tools/fixtures/init-daemon-squid3 /etc/init.d/squid3
    cp /usr/local/src/aron-tools/fixtures/interfaces /etc/network/
    /etc/init.d/squid3 start
    rm -rfv /usr/local/src/aron-tools
    rm -rfv /usr/local/src/django-suit
    clear;
    echo "Making cache directory ... after finish the system will be rebooted"
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
