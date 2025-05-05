#!/bin/bash

# === CONFIGURACIÓN: MODIFICA SOLO ESTAS VARIABLES ===

DOMINIO="tudominio.com"
HOSTNAME="mail.tudominio.com"
DBUSER="mailuser"
DBPASS="tu_contraseña"
DBNAME="mailserver"

# === NO MODIFIQUES NADA DEBAJO DE ESTA LÍNEA ===

# Archivos de configuración
MAIN_CF="/etc/postfix/main.cf"
MASTER_CF="/etc/postfix/master.cf"
BOUNCE_CF="/etc/postfix/bounce.cf"
HEADER_CHECKS="/etc/postfix/header_checks"

# Archivos MySQL
MYSQL_DOMAINS="/etc/postfix/mysql-virtual-mailbox-domains.cf"
MYSQL_USERS="/etc/postfix/mysql-virtual-mailbox-maps.cf"
MYSQL_ALIAS="/etc/postfix/mysql-virtual-alias-maps.cf"
MYSQL_EMAIL2EMAIL="/etc/postfix/mysql-virtual-email2email.cf"

echo "Instalando paquetes necesarios..."
sudo apt update
sudo apt install -y postfix postfix-mysql postsrsd

echo "Configurando $MAIN_CF ..."
sudo bash -c "cat > $MAIN_CF" <<EOF
smtpd_banner = \$myhostname ESMTP \$mail_name (Ubuntu)
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 3.6

# TLS parameters
smtpd_tls_cert_file = /etc/ssl/certs/$HOSTNAME.crt
smtpd_tls_key_file = /etc/ssl/private/$HOSTNAME.key
smtpd_use_tls = yes
smtpd_tls_auth_only = yes
smtp_tls_security_level = may
smtpd_tls_security_level = may

# Authentication
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes

smtpd_helo_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname
smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unknown_recipient_domain, reject_unlisted_recipient, reject_unauth_destination, reject_rbl_client dul.dnsbl.sorbs.net, reject_rbl_client sbl-xbl.spamhaus.org, reject_rbl_client bl.spamcop.net
smtpd_sender_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_sender, reject_unknown_sender_domain
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, defer_unauth_destination

myhostname = $HOSTNAME
mydomain = $DOMINIO
myorigin = \$mydomain
mydestination = \$myhostname, localhost.localdomain, localhost
relayhost =
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
smtp_dns_support_level = enabled
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all

virtual_transport = lmtp:unix:private/dovecot-lmtp

virtual_mailbox_domains = mysql:$MYSQL_DOMAINS
virtual_mailbox_maps = mysql:$MYSQL_USERS
virtual_alias_maps = mysql:$MYSQL_ALIAS, mysql:$MYSQL_EMAIL2EMAIL

disable_vrfy_command = yes
strict_rfc821_envelopes = yes
smtpd_delay_reject = yes
smtpd_helo_required = yes
smtp_always_send_ehlo = yes
smtpd_timeout = 30s
smtp_helo_timeout = 15s
smtp_rcpt_timeout = 15s
smtpd_recipient_limit = 20
minimal_backoff_time = 180s
maximal_backoff_time = 3h

invalid_hostname_reject_code = 550
non_fqdn_reject_code = 550
unknown_address_reject_code = 550
unknown_client_reject_code = 550
unknown_hostname_reject_code = 550
unverified_recipient_reject_code = 550
unverified_sender_reject_code = 550
unknown_local_recipient_reject_code = 450
bounce_queue_lifetime = 3d
bounce_template_file = $BOUNCE_CF
maximal_queue_lifetime = 4d
header_checks = regexp:$HEADER_CHECKS
smtpd_soft_error_limit = 3
smtpd_hard_error_limit = 12
message_size_limit = 20480000

# PostfixSRS
sender_canonical_maps = tcp:localhost:10001
sender_canonical_classes = envelope_sender
recipient_canonical_maps = tcp:localhost:10002
recipient_canonical_classes = envelope_recipient
EOF

echo "Configurando $BOUNCE_CF ..."
sudo bash -c "cat > $BOUNCE_CF" <<EOF
failure_template = <<EOM
Charset: UTF-8
From: MAILER-DAEMON (Mail Delivery System)
Subject: Servidor de correo: Mensaje no entregado
Postmaster-Subject: Postmaster: Mensaje no entregado

POR FAVOR, LEA DETENIDAMENTE ESTE MENSAJE.
Éste es un mensaje de correo enviado automáticamente por su servidor de correo.
No ha sido posible entregar su mensaje a uno o más destinatarios.
El mensaje que causó el error está adjunto a este mensaje.
EOM

delay_template = <<EOM
Charset: UTF-8
From: MAILER-DAEMON (Mail Delivery System)
Subject: Servidor de correo: Mensaje postpuesto
Postmaster-Subject: Postmaster: Mensaje postpuesto

POR FAVOR, LEA DETENIDAMENTE ESTE MENSAJE.
Este es un mensaje de correo enviado automáticamente por el servidor de correo.
.
##############################################
# ÉSTE ES SÓLO UN MENSAJE DE AVISO           #
# NO ES NECESARIO QUE REENVÍE EL MENSAJE.    #
##############################################

Su mensaje no pudo ser entregado al destinatario después de intentarlo durante \$delay_warning_time_hours hora(s).
Se seguirá intentando enviar el mensaje hasta que pasen \$maximal_queue_lifetime_days días.
EOM

success_template = <<EOM
Charset: UTF-8
From: MAILER-DAEMON (Mail Delivery System)
Subject: Servidor de correo: Informe de entrega correcta de mensaje

POR FAVOR, LEA DETENIDAMENTE ESTE MENSAJE.
Este es un mensaje de correo enviado automáticamente por su servidor de correo.
Su mensaje fue entregado correctamente al/a los destinatario/s indicados a continuación.
Si el mensaje fue entregado directamente a los destinatarios, no recibirá más notificaciones; en caso contrario, si el mensaje tuviera que pasar por más servidores de correo, es posible que reciba más notificaciones de estos servidores.
EOM

verify_template = <<EOM
Charset: UTF-8
From: MAILER-DAEMON (Mail Delivery System)
Subject: Servidor de correo: Informe de estado de entrega de mensaje

POR FAVOR, LEA DETENIDAMENTE ESTE MENSAJE.
Este es un mensaje de correo enviado automáticamente por su servidor de correo.
Adjunto a este mensaje se encuentra el informe de entrega solicitado.
EOM
EOF

echo "Configurando $HEADER_CHECKS ..."
sudo bash -c "cat > $HEADER_CHECKS" <<EOF
/^subject:/ WARN
EOF
sudo postmap $HEADER_CHECKS

echo "Configurando archivos MySQL de Postfix..."

sudo bash -c "cat > $MYSQL_DOMAINS" <<EOF
user = $DBUSER
password = $DBPASS
hosts = 127.0.0.1
dbname = $DBNAME
query = SELECT 1 FROM virtual_domains WHERE name='%s' AND active='1'
EOF

sudo bash -c "cat > $MYSQL_USERS" <<EOF
user = $DBUSER
password = $DBPASS
hosts = 127.0.0.1
dbname = $DBNAME
query = SELECT 1 FROM virtual_users WHERE email='%s' AND active='1'
EOF

sudo bash -c "cat > $MYSQL_ALIAS" <<EOF
user = $DBUSER
password = $DBPASS
hosts = 127.0.0.1
dbname = $DBNAME
query = SELECT destination FROM virtual_aliases WHERE source='%s' AND active='1'
EOF

sudo bash -c "cat > $MYSQL_EMAIL2EMAIL" <<EOF
user = $DBUSER
password = $DBPASS
hosts = 127.0.0.1
dbname = $DBNAME
query = SELECT email FROM virtual_users WHERE email='%s' and active='1'
EOF

echo "Configurando $MASTER_CF ..."
sudo cp $MASTER_CF ${MASTER_CF}.bak
sudo bash -c "cat > $MASTER_CF" <<EOF
smtp      inet  n       -       y       -       -       smtpd
smtps     inet  n       -       y       -       -       smtpd -o syslog_name=postfix/smtps -o smtpd_tls_wrappermode=yes -o smtpd_sasl_auth_enable=yes -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
submission inet n       -       y       -       -       smtpd -o syslog_name=postfix/submission -o smtpd_tls_security_level=encrypt -o smtpd_sasl_auth_enable=yes -o smtpd_sasl_type=dovecot -o smtpd_sasl_path=private/auth -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
pickup    unix  n       -       y       60      1       pickup
cleanup   unix  n       -       y       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       y       1000?   1       tlsmgr
rewrite   unix  -       -       y       -       -       trivial-rewrite
bounce    unix  -       -       y       -       0       bounce
defer     unix  -       -       y       -       0       bounce
trace     unix  -       -       y       -       0       bounce
verify    unix  -       -       y       -       1       verify
flush     unix  n       -       y       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       y       -       -       smtp
relay     unix  -       -       y       -       -       smtp -o syslog_name=postfix/\$service_name
showq     unix  n       -       y       -       -       showq
error     unix  -       -       y       -       -       error
retry     unix  -       -       y       -       -       error
discard   unix  -       -       y       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       y       -       -       lmtp
anvil     unix  -       -       y       -       1       anvil
scache    unix  -       -       y       -       1       scache
postlog   unix-dgram n  -       n       -       1       postlogd
EOF

echo "Recargando configuración de Postfix y postsrsd..."
sudo systemctl restart postfix
sudo systemctl restart postsrsd

echo "=== Configuración completada ==="
echo "¡No olvides revisar los certificados TLS y la base de datos MySQL!"
