#!/bin/bash

# settings for AWS SES
postconf -e \
  "relayhost = [${SMTP_HOST}]:2587" \
  "inet_protocols = ipv4" \
  "smtp_sasl_auth_enable = yes" \
  "smtp_sasl_security_options = noanonymous" \
  "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" \
  "smtp_use_tls = yes" \
  "smtp_tls_security_level = encrypt" \
  "smtp_tls_note_starttls_offer = yes"

echo "[${SMTP_HOST}]:${SMTP_PORT:-2587} ${SMTP_USERNAME}:${SMTP_PASSWORD}" > /etc/postfix/sasl_passwd

postmap hash:/etc/postfix/sasl_passwd

# settings for error and bounce mail recipient
# (@see https://stackoverflow.com/questions/24179706/how-to-receive-bounced-mail-using-aws-ses-with-postfix)
# (@see https://open-groove.net/other-tools/mail-forward/)
# The list of error classes that are reported
postconf -e \
 "notify_classes = bounce, delay, policy, protocol, resource, software" \
 "bounce_notice_recipient = ${SMTP_POSTMASTER_MAIL_ADDRESS}" \
 "2bounce_notice_recipient = ${SMTP_POSTMASTER_MAIL_ADDRESS}" \
 "error_notice_recipient = ${SMTP_POSTMASTER_MAIL_ADDRESS}"
# "alias_maps = hash:/etc/postfix/aliases" \
# "alias_database = hash:/etc/postfix/aliases"

# echo "bounceuser: ${SMTP_POSTMASTER_MAIL_ADDRESS}" > /etc/postfix/aliases

# newaliases

# extra settings for bounce mail.
# Bounce mail messages are not sent because envelop from of bounce mail is empty,
# so change it using address mapping.
# (@see https://ameblo.jp/server-study/entry-10270572107.html)

#postconf -e "canonical_classes = envelope_sender"
#echo '//' ${SMTP_ENVELOPE_FROM_ADDRESS} > /etc/postfix/sender_canonical.regexp
#postconf -e \
# "sender_canonical_classes = envelope_sender" \
# "sender_canonical_maps = regexp:/etc/postfix/sender_canonical.regexp"
#
#echo "/${SMTP_ENVELOPE_FROM_ADDRESS}/ ${SMTP_POSTMASTER_MAIL_ADDRESS}" > /etc/postfix/recipient_canonical.regexp
#postconf -e \
# "recipient_canonical_classes = envelope_recipient" \
# "recipient_canonical_maps = regexp:/etc/postfix/recipient_canonical.regexp"

# debug level
#postconf -e \
# "debug_peer_list = email-smtp.ap-northeast-1.amazonaws.com" \
# "debug_peer_level = 3"

# Copy /etc/resolv.conf to /var/spool/postfix/etc/resolv.conf so that postfix can reference it
# even after it did chroot to /var/spool/postfix.
# @see https://newbedev.com/postfix-in-docker-host-or-domain-name-not-found-dns-and-docker
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

## Allow for overriding every config
for e in ${!POSTFIX_*} ; do postconf -e "${e:8}=${!e}" ; done

rm -f /var/spool/postfix/pid/master.pid

exec "$@"
