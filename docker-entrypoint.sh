#!/bin/bash

postconf -e "relayhost = [${SMTP_HOST}]:2587" \
"inet_protocols = ipv4" \
"smtp_sasl_auth_enable = yes" \
"smtp_sasl_security_options = noanonymous" \
"smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" \
"smtp_use_tls = yes" \
"smtp_tls_security_level = encrypt" \
"smtp_tls_note_starttls_offer = yes"

echo "[${SMTP_HOST}]:2587 ${SMTP_USERNAME}:${SMTP_PASSWORD}" > /etc/postfix/sasl_passwd

postmap hash:/etc/postfix/sasl_passwd

# Copy /etc/resolv.conf to /var/spool/postfix/etc/resolv.conf so that postfix can reference it
# even after it did chroot to /var/spool/postfix.
# @see https://newbedev.com/postfix-in-docker-host-or-domain-name-not-found-dns-and-docker
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

## Allow for overriding every config
for e in ${!POSTFIX_*} ; do postconf -e "${e:8}=${!e}" ; done

rm -f /var/spool/postfix/pid/master.pid

exec "$@"
