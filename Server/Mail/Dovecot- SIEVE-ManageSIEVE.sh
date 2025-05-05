#!/bin/bash

# === CONFIGURA SOLO ESTAS VARIABLES ===
DOMINIO="tudominio.com"
HOSTNAME="mail.tudominio.com"
DBUSER="mailuser"
DBPASS="tu_contraseña"
DBNAME="mailserver"
CERT="/etc/ssl/certs/${HOSTNAME}.crt"
KEY="/etc/ssl/private/${HOSTNAME}.key"
POSTMASTER="postmaster@${DOMINIO}"

# === NO MODIFIQUES NADA DEBAJO DE ESTA LÍNEA ===

set -e

echo "Instalando paquetes necesarios..."
sudo apt update
sudo apt install -y dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql dovecot-sieve dovecot-managesieved

echo "Haciendo copias de seguridad de archivos importantes..."
sudo cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig || true
sudo cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.orig || true
sudo cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.orig || true
sudo cp /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.orig || true
sudo cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.orig || true
sudo cp /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.orig || true
sudo cp /etc/dovecot/conf.d/auth-system.conf.ext /etc/dovecot/conf.d/auth-system.conf.ext.orig || true

echo "Configurando /etc/dovecot/dovecot.conf ..."
sudo bash -c "cat > /etc/dovecot/dovecot.conf" <<EOF
protocols = imap pop3 lmtp sieve
postmaster_address = $POSTMASTER
EOF

echo "Configurando /etc/dovecot/conf.d/10-mail.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/10-mail.conf" <<EOF
mail_location = maildir:/var/mail/vhosts/%d/%n
namespace inbox {
  inbox = yes
}
EOF

echo "Creando usuario y directorios de correo..."
sudo mkdir -p /var/mail/vhosts
sudo groupadd -g 5000 vmail || true
sudo useradd -g vmail -u 5000 vmail -d /var/mail || true
sudo chown -R vmail:vmail /var/mail

echo "Configurando /etc/dovecot/conf.d/10-auth.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/10-auth.conf" <<EOF
disable_plaintext_auth = yes
auth_mechanisms = plain login
!include auth-system.conf.ext
!include auth-sql.conf.ext
EOF

echo "Configurando /etc/dovecot/conf.d/auth-sql.conf.ext ..."
sudo bash -c "cat > /etc/dovecot/conf.d/auth-sql.conf.ext" <<EOF
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
}
EOF

echo "Configurando /etc/dovecot/dovecot-sql.conf.ext ..."
sudo bash -c "cat > /etc/dovecot/dovecot-sql.conf.ext" <<EOF
driver = mysql
connect = host=127.0.0.1 dbname=$DBNAME user=$DBUSER password=$DBPASS
default_pass_scheme = PLAIN-MD5
password_query = SELECT email AS user, password FROM virtual_users WHERE email='%u' AND active='1';
EOF

echo "Configurando /etc/dovecot/conf.d/10-master.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/10-master.conf" <<EOF
service imap-login {
  inet_listener imap {
    port = 0
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}
service pop3-login {
  inet_listener pop3 {
    port = 0
  }
  inet_listener pop3s {
    port = 995
    ssl = yes
  }
}
service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0666
    user = postfix
    group = postfix
  }
}
service auth {
  unix_listener auth-userdb {
    mode = 0600
    user = vmail
  }
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
  user = dovecot
}
service auth-worker {
  user = vmail
}
EOF

echo "Configurando /etc/dovecot/conf.d/10-ssl.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/10-ssl.conf" <<EOF
ssl = required
ssl_cert = <$CERT
ssl_key = <$KEY
EOF

echo "Configurando logs personalizados en /etc/dovecot/conf.d/10-logging.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/10-logging.conf" <<EOF
log_path = /var/log/dovecot.log
log_timestamp = "%b %d %H:%M:%S "
login_log_format_elements = user=<%u> method=%m rip=%r lip=%l mpid=%e %c
login_log_format = %$: %s
mail_log_prefix = "%s(%u)<%{pid}><%{session}>: "
deliver_log_format = Message-ID: %m - Subject: %s - From: %f - Size: %p - Status: %$
plugin {
  mail_log_events = delete undelete expunge copy mailbox_delete mailbox_rename
  mail_log_fields = uid box msgid size
}
EOF

echo "Configurando carpetas predeterminadas en /etc/dovecot/conf.d/15-mailboxes.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/15-mailboxes.conf" <<EOF
namespace inbox {
  mailbox Drafts {
    special_use = \Drafts
    auto = subscribe
  }
  mailbox Spam {
    special_use = \Junk
    auto = subscribe
  }
  mailbox Trash {
    special_use = \Trash
    auto = subscribe
  }
  mailbox Sent {
    special_use = \Sent
    auto = subscribe
  }
}
EOF

echo "Configurando IMAP en /etc/dovecot/conf.d/20-imap.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/20-imap.conf" <<EOF
imap_logout_format = in=%i out=%o deleted=%{deleted} expunged=%{expunged}
protocol imap {
  mail_plugins = \$mail_plugins mail_log notify
  mail_max_userip_connections = 10
}
EOF

echo "Configurando POP3 en /etc/dovecot/conf.d/20-pop3.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/20-pop3.conf" <<EOF
pop3_logout_format = top=%t/%p, retr=%r/%b, del=%d/%m, size=%s
protocol pop3 {
  mail_plugins = \$mail_plugins mail_log notify
  mail_max_userip_connections = 10
}
EOF

echo "Desactivando autenticación PAM en /etc/dovecot/conf.d/auth-system.conf.ext ..."
sudo sed -i 's/^passdb {/###passdb {/' /etc/dovecot/conf.d/auth-system.conf.ext
sudo sed -i 's/^  driver = pam/###  driver = pam/' /etc/dovecot/conf.d/auth-system.conf.ext
sudo sed -i 's/^userdb {/###userdb {/' /etc/dovecot/conf.d/auth-system.conf.ext
sudo sed -i 's/^  driver = passwd/###  driver = passwd/' /etc/dovecot/conf.d/auth-system.conf.ext

echo "Configurando Sieve en /etc/dovecot/conf.d/20-lmtp.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/20-lmtp.conf" <<EOF
protocol lmtp {
  mail_plugins = \$mail_plugins sieve
}
EOF

echo "Configurando Sieve en /etc/dovecot/conf.d/90-sieve.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/90-sieve.conf" <<EOF
plugin {
  sieve = ~/.dovecot.sieve
  sieve_global_path = /var/lib/dovecot/sieve/default.sieve
  sieve_dir = ~/sieve
  sieve_global_dir = /var/lib/dovecot/sieve/
}
EOF

echo "Configurando ManageSIEVE en /etc/dovecot/conf.d/20-managesieve.conf ..."
sudo bash -c "cat > /etc/dovecot/conf.d/20-managesieve.conf" <<EOF
service managesieve-login {
  inet_listener sieve {
    port = 4190
  }
}
service managesieve {
  process_limit = 1024
}
EOF

echo "Creando archivo de reglas Sieve global..."
sudo mkdir -p /var/lib/dovecot/sieve
sudo bash -c "cat > /var/lib/dovecot/sieve/default.sieve" <<EOF
require "fileinto";
if header :contains "X-Spam-Flag" "YES" {
  fileinto "Junk";
}
EOF
sudo sievec /var/lib/dovecot/sieve/default.sieve
sudo chown -R vmail:vmail /var/lib/dovecot

echo "Permisos para Postfix..."
sudo chmod -R 755 /etc/postfix

echo "Reiniciando Dovecot..."
sudo systemctl restart dovecot

echo "=== Configuración completada ==="
echo "Puedes verificar el servicio ManageSIEVE con: telnet $(hostname -I | awk '{print $1}') 4190"
