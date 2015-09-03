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
    apt-get update;
    apt-get -f dist-upgrade;
    cd /usr/local/src;
    git clone http://aron.ctimeapps.it/tony/aron-tools.git
    cd /usr/local/src/aron-tools.git
    apt-get -y install squid3 dansguardian python-mysqldb python-django python-pip python-crypto exim4-daemon-heavy dovecot-mysql firehol clamav-daemon git apache2 libapache2-mod-wsgi isc-dhcp-server libsodium-dev sudo hdparm;
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQLPASS"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQLPASS"
    apt-get -y install mysql-server
    cd /usr/local/src;
    git clone http://aron.ctimeapps.it/tony/aron-web.git;
    pip install singlemodeladmin;
    pip install django-sizefield;
    pip install libnacl;
    pip install base58;
    pip install iptools;
    git clone https://github.com/darklow/django-suit;
    cd django-suit;
    python setup.py install;
    cp /usr/local/src/aron-web/fixtures/base.html /usr/local/lib/python2.7/dist-packages/django_suit-0.2.14-py2.7.egg/suit/templates/admin/base.html;
    cp /usr/local/src/aron-web/fixtures/config.py /usr/local/lib/python2.7/dist-packages/django_suit-0.2.14-py2.7.egg/suit/config.py;
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
    python manage.py migrate;
    mysql -u aron -h localhost --database=aron --password=$ARONPASS < /usr/local/src/aron-web/fixtures/loaddata.sql;
    mv /usr/local/src/aron-tools/fixtures/config.py /usr/local/lib/python2.7/dist-packages/django_suit-0.2.14-py2.7.egg/suit/config.py
    mv /usr/local/src/aron-tools/fixtures/base.html /usr/local/lib/python2.7/dist-packages/django_suit-0.2.14-py2.7.egg/suit/templates/admin/base.html
    mv /usr/local/src/aron-tools/fixtures/aron.conf /etc/apache2/sites-available/;
    mv /usr/local/src/aron-tools/fixtures/firehol.conf /etc/firehol/
    mv /usr/local/src/aron-tools/fixtures/dansguardian.conf /etc/dansguardian/
    mv /usr/local/src/aron-tools/fixtures/squid.conf /etc/squid3/
    mv /usr/local/src/aron-tools/fixtures/logfile-daemon_mysql.pl /usr/lib/squid3/
    a2ensite aron.conf;
    /etc/init.d/apache2 restart;
    ifconfig eth1 192.168.0.1 netmask 255.255.255.0 up;
else
    echo "Errore: Devi essere root prima per eseguire questo script"
fi
