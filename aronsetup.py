#!/usr/bin/env python

import aronmanager
from Crypto.Cipher import AES
from modules import sql
import base64
import getpass
import ConfigParser
import os

os.system("clear")
print(2*'\n')
print("Questo script viene eseguito per inserire il password 'admin' di Aron Manager,\n")
print("ATTENZIONE, alla fine dell'esecuzione dello script si autodistrugge.")
print(2*'\n')
lic = raw_input("Licensa consegnata da CTIME per AronManager?: ")
password = getpass.getpass("Password per admin: ")
block_size = 32
padding = '{'
pad = lambda s: s + (block_size - len(s) % block_size) * padding
encode_aes = lambda c, s: base64.b64encode(c.encrypt(pad(s)))
cipher = AES.new(lic)
encoded_admin = encode_aes(cipher, 'admin')
encoded = encode_aes(cipher, password)
sql.query('new_account', encoded_admin, encoded, 2, 2, 2, 2)
config = ConfigParser.RawConfigParser()
config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), './settings/config.cfg')
config.read(config_file)
config.set('Settings', 'lic', lic)
with open(config_file, 'wb') as configfile:
    config.write(configfile)

os.system("rm -f aronmanager.py")
os.system("rm -f modules/crypt.py")
os.system("rm -f modules/domaintools.py")
os.system("rm -f modules/data.py")
os.system("rm -f modules/MainWindow.py")
os.system("rm -f modules/sql.py")
os.system("rm -f modules/__init__.py")
os.system("rm -f __init__.py")
os.system("chmod 500 aronmanager.pyc")
os.system("mv aronmanager.pyc aron-manager")
os.system("rm -f aronsetup.pyc")
