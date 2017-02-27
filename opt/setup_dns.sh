#!/bin/sh
HOSTNAME=$(hostname -s) || echo $EXT_HOST
DOMAIN=$(hostname -d) || echo $EXT_DOMAIN
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

# Configure DNS option

cat <<EOF >> /etc/named.conf
zone "${DOMAIN}" {
	type master;
	file "${DOMAIN}.fwd";
};

zone "${REV_IP}.in-addr.arpa" {
	type master;
	file "${DOMAIN}.rev";
};
EOF

cat <<EOF > /var/named/${DOMAIN}.fwd
\$TTL	3D
@	SOA	ns.${DOMAIN}. root.${DOMAIN}. ( 1 4h 1h 1w 1h )
@	IN	NS	ns.${DOMAIN}.
		IN	MX	10	zimbra.${DOMAIN}.
ns		IN	A	${SERVER_IP}
www		IN	A	${SERVER_IP}
mail		IN	A	${SERVER_IP}
zimbra		IN	A	${SERVER_IP}
EOF

cat <<EOF > /var/named/${DOMAIN}.rev
\$TTL	3D
@	SOA	ns.${DOMAIN}. root.${DOMAIN}. ( 1 4h 1h 1w 1h )
@	IN	NS	ns.${DOMAIN}.

${REV_LAST}	IN	PTR	ns.${DOMAIN}.
EOF

cat <<EOF > /etc/resolv.conf
nameserver 127.0.0.1
nameserver 8.8.8.8
EOF

echo BIND config
echo ====================
cat /etc/named.conf
echo ====================
cat /var/named/${DOMAIN}.fwd
echo ====================
cat /var/named/${DOMAIN}.rev
echo ====================

service named restart
