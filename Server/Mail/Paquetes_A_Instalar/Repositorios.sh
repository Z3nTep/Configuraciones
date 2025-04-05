#!/bin/bash
# Instalación de los paquetes

# Postfix y PostfixSRS
sudo apt update && sudo apt install -y \
    dnsutils \
    postfix postfix-mysql \
    dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql \
    mysql-server \
    apache2 \
    bind9

# Dovecot, SIEVE y ManageSIEVE
sudo apt install -y dovecot-sieve dovecot-managesieved

# SPF, DKIM y DMARC
sudo apt install -y opendkim opendkim-tools postfix-policyd-spf-python postfix-pcre

# Postgrey
sudo apt install -y postgrey

# Amavis, ClamAV y SpamAssassin
sudo apt install -y amavisd-new spamassassin clamav clamav-daemon

# Rainloop
sudo wget https://www.rainloop.net/repository/webmail/rainloop-latest.zip
sudo apt install unzip
sudo unzip rainloop-latest.zip
sudo rm rainloop-latest.zip

# Fail2Ban y buzón nuevo con mailutils
sudo apt install -y fail2ban mailutils