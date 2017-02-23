#!/bin/sh
HOSTNAME=$(hostname -s)
DOMAIN=$(hostname -d)
FQDN="${HOSTNAME}.${DOMAIN}"
SERVER_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
REV_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'|awk -F. '{print $3"."$2"."$1}')
REV_LAST=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'|awk -F. '{print $4}')

# Display variables for debugging

echo hostname - $HOSTNAME
echo domain - $DOMAIN
echo fqdn - $FQDN
echo server IP - $SERVER_IP
echo arp - $REV_IP

echo "Enable/disable other services"
# Disable SMTP
service postfix stop
service sendmail stop
service sshd start
service crond start
service rsyslog start

# Add server IP on host file

#echo Adding $HOSTNAME to /etc/hosts
#echo "$SERVER_IP	$FQDN	$HOSTNAME" >> /etc/hosts
echo "========================"
cat /etc/hosts
echo "========================"
cat /etc/resolv.conf

echo "Configure DNS for ${HOSTNAME}.${DOMAIN}"
/opt/setup_dns.sh

echo "Extract zimbra installer"
tar -xzvf /opt/zcs-8.0.2_GA_5569.RHEL6_64.20121210115059.tgz -C /opt/zimbra_installer


echo "Install ZIMBRA"
echo "========================"
cd /opt/zimbra_installer/zcs-* && ./install.sh -s --platform-override < /opt/all_yes
echo "========================"

echo "Create zimbra config"
/opt/create_zimbra_config.sh /opt/zimbra_config_generated

echo "Zimbra config dump"
cat /opt/zimbra_config_generated

echo "Configure Zimbra"
/opt/zimbra/libexec/zmsetup.pl -c /opt/zimbra_config_generated

echo "Fix rsyslog"
cat <<EOF >> /etc/rsyslog.conf
\$ModLoad imudp
\$UDPServerRun 514
EOF
service rsyslog restart

echo "Fix RED status"
/opt/zimbra/libexec/zmsyslogsetup

echo "Run zmupdatekeys as zimbra"
su -c /opt/zimbra/bin/zmupdateauthkeys zimbra

echo "Restart Zimbra"
service zimbra restart

echo "Restart CROND"
service crond restart

echo "Server is ready..."

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi
