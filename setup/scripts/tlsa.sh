#!/bin/sh
#VERSION=0.2
# This script is written by Martynas Bendorius and DirectAdmin
# It is used to recreate tlsa records for domain
# Official DirectAdmin webpage: http://www.directadmin.com
# Usage:
# ./tlsa <domain>
MYUID=`/usr/bin/id -u`
if [ "${MYUID}" != 0 ]; then
	echo "You require Root Access to run this script";
	exit 0;
fi

DA_BIN=/usr/local/directadmin/directadmin
TASK_QUEUE=/usr/local/directadmin/data/task.queue.cb

if [ $# -ne 2 ]; then
	echo "usage: $0 <domain> <web|mail|all>" 
	exit 1
fi

OPENSSL=/usr/bin/openssl

run_dataskq() {
	DATASKQ_OPT=$1
	/usr/local/directadmin/dataskq ${DATASKQ_OPT} --custombuild
}

DOMAIN=$1
TLSATYPE=$2
case "$TLSATYPE" in
	"all")
		;;
	"web")
		;;
	"mail")
		;;
	*)
		echo "usage: $0 <domain> <web|mail|all>"
		exit 1
esac

DOMAINARR=`echo "${DOMAIN}" | perl -p0 -e "s/,/ /g"`

FOUNDDOMAIN=0
for TDOMAIN in ${DOMAINARR}
do
	DOMAIN=${TDOMAIN}

	DOMAIN_ESCAPED="`echo ${DOMAIN} | perl -p0 -e 's#\.#\\\.#g'`"

	if grep -m1 -q "^${DOMAIN_ESCAPED}:" /etc/virtual/domainowners; then
		USER=`grep -m1 "^${DOMAIN_ESCAPED}:" /etc/virtual/domainowners | cut -d' ' -f2`
		HOSTNAME=0
		FOUNDDOMAIN=1
		break
	elif grep -m1 -q "^${DOMAIN_ESCAPED}$" /etc/virtual/domains; then
		USER="root"
		if ${DA_BIN} c | grep -m1 -q "^servername=${DOMAIN_ESCAPED}\$"; then
			HOSTNAME=1
			FOUNDDOMAIN=1
			break
		else
			echo "Domain exists in /etc/virtual/domains, but is not set as a hostname in DirectAdmin. Unable to find 'servername=${DOMAIN}' in the output of '/usr/local/directadmin/directadmin c'."
			#exit 1
		fi
	else
		echo "Domain does not exist on the system. Unable to find ${DOMAIN} in /etc/virtual/domainowners."
		#exit 1
	fi
done

if [ ${FOUNDDOMAIN} -eq 0 ]; then
	echo "no valid domain found - exiting"
	exit 1
fi

DA_USERDIR="/usr/local/directadmin/data/users/${USER}"
DA_CONFDIR="/usr/local/directadmin/conf"

if [ ! -d "${DA_USERDIR}" ] && [ "${HOSTNAME}" -eq 0 ]; then
	echo "${DA_USERDIR} not found, exiting..."
	exit 1
elif [ ! -d "${DA_CONFDIR}" ] && [ "${HOSTNAME}" -eq 1 ]; then
	echo "${DA_CONFDIR} not found, exiting..."
	exit 1
fi

try_gen_tlsa() {
	if [ ! -x /usr/local/directadmin/directadmin ]; then
		echo 1
	else
		if ! /usr/local/directadmin/directadmin c | grep -m1 -q '^dns_tlsa=1$'; then
			echo 2
		else
			if [ "${HOSTNAME}" -eq 0 ]; then
				CERT="${DA_USERDIR}/domains/${DOMAIN}.cert"
			else
				CERT=`${DA_BIN} c |grep ^cacert= | cut -d= -f2`
			fi
	
			if [ ! -f "${CERT}" ] && [ "$TLSATYPE" == "web" ]; then
				echo 2
			else
				#TLSA_HASH_SHA256=`${OPENSSL} x509 -in ${CERT} -outform DER | ${OPENSSL} sha256 | cut -d' ' -f2`
				#TLSA_HASH_SHA512=`${OPENSSL} x509 -in ${CERT} -outform DER | ${OPENSSL} sha512 | cut -d' ' -f2`
				#TLSA_HASH_SHA256_PUB=`${OPENSSL} x509 -in ${CERT} -noout -pubkey | ${OPENSSL} pkey -pubin -outform DER |${OPENSSL} sha256 | cut -d' ' -f2`
				#TLSA_HASH_SHA512_PUB=`${OPENSSL} x509 -in ${CERT} -noout -pubkey | ${OPENSSL} pkey -pubin -outform DER |${OPENSSL} sha512 | cut -d' ' -f2`

				#CATLSA_HASH_SHA256=`${OPENSSL} x509 -in ${CACERT} -outform DER | ${OPENSSL} sha256 | cut -d' ' -f2`
				#CATLSA_HASH_SHA512=`${OPENSSL} x509 -in ${CACERT} -outform DER | ${OPENSSL} sha512 | cut -d' ' -f2`
				#CATLSA_HASH_SHA256_PUB=`${OPENSSL} x509 -in ${CACERT} -noout -pubkey | ${OPENSSL} pkey -pubin -outform DER |${OPENSSL} sha256 | cut -d' ' -f2`
				#CATLSA_HASH_SHA512_PUB=`${OPENSSL} x509 -in ${CACERT} -noout -pubkey | ${OPENSSL} pkey -pubin -outform DER |${OPENSSL} sha512 | cut -d' ' -f2`

				GENERATED=0
				if [ "$TLSATYPE" == "web" ] || [ "$TLSATYPE" == "all" ]; then
    					TLSA_HASH_SHA256_PUB=`${OPENSSL} x509 -in ${CERT} -noout -pubkey | ${OPENSSL} pkey -pubin -outform DER |${OPENSSL} sha256 | cut -d' ' -f2`
			            DNSLIST=`openssl x509 -in ${CERT} -text -noout| grep -A1 "Subject Alternative Name"|tail -1`
					for DNSN in ${DNSLIST}; do {
						DNSN=`echo ${DNSN}|cut -d':' -f2| tr -d ','`
						if [ "${DNSN}" == "${DOMAIN}" ]; then
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 3 0 1 ${TLSA_HASH_SHA256}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 3 0 2 ${TLSA_HASH_SHA512}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 3 1 1 ${TLSA_HASH_SHA256_PUB}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 3 1 2 ${TLSA_HASH_SHA512_PUB}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 2 0 1 ${CATLSA_HASH_SHA256}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 2 0 2 ${CATLSA_HASH_SHA512}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 2 1 1 ${CATLSA_HASH_SHA256_PUB}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 2 1 2 ${CATLSA_HASH_SHA512_PUB}"
							HOST_TLSA="_443._tcp.${DNSN}."
							HOST_TLSA_VAL="3 1 1 ${TLSA_HASH_SHA256_PUB}"
							DOM256="_443._tcp.${DNSN}. 300 IN TLSA 3 1 1 ${TLSA_HASH_SHA256_PUB}"
							echo "action=dns&do=delete&domain=${DOMAIN}&type=TLSA&name=${HOST_TLSA}" >> ${TASK_QUEUE}
							run_dataskq
							echo "action=dns&do=add&domain=${DOMAIN}&type=TLSA&name=${HOST_TLSA}&value=${HOST_TLSA_VAL}&ttl=300&named_reload=yes" >> ${TASK_QUEUE}
							run_dataskq
							GENERATED=1
						elif [ "${DNSN}" == "www.${DOMAIN}" ]; then
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 3 0 1 ${TLSA_HASH_SHA256}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 3 0 2 ${TLSA_HASH_SHA512}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 3 1 1 ${TLSA_HASH_SHA256_PUB}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 3 1 2 ${TLSA_HASH_SHA512_PUB}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 2 0 1 ${CATLSA_HASH_SHA256}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 2 0 2 ${CATLSA_HASH_SHA512}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 2 1 1 ${CATLSA_HASH_SHA256_PUB}"
							#echo "_443._tcp.${DNSN}. 300 IN TLSA 2 1 2 ${CATLSA_HASH_SHA512_PUB}"
							HOST_TLSA="_443._tcp.${DNSN}."
							HOST_TLSA_VAL="3 1 1 ${TLSA_HASH_SHA256_PUB}"
							DOM256="_443._tcp.${DNSN}. 300 IN TLSA 3 1 1 ${TLSA_HASH_SHA256_PUB}"
							echo "action=dns&do=delete&domain=${DOMAIN}&type=TLSA&name=${HOST_TLSA}" >> ${TASK_QUEUE}
							run_dataskq
							echo "action=dns&do=add&domain=${DOMAIN}&type=TLSA&name=${HOST_TLSA}&value=${HOST_TLSA_VAL}&ttl=300&named_reload=yes" >> ${TASK_QUEUE}
							run_dataskq
							GENERATED=1
						fi
					}; done
               			fi

				if [ "$TLSATYPE" == "mail" ] || [ "$TLSATYPE" == "all" ]; then
					HOSTSMTPGEN=0
			                TLSA_HASH_SHA256_PUBEXIM=`${OPENSSL} x509 -in /etc/exim.cert -noout -pubkey | ${OPENSSL} pkey -pubin -outform DER |${OPENSSL} sha256 | cut -d' ' -f2`
					NAMEDDIR=`/usr/local/directadmin/directadmin c | grep nameddir | awk -F'=' '{print $2}'`
					if [ -f ${NAMEDDIR}/${DOMAIN}.db ]; then
						while read LINE; do
							if echo "$LINE" | egrep "^${DOMAIN}\." |grep MX > /dev/null 2>&1; then
								MXR="$LINE"
								if [ $HOSTSMTPGEN -eq 0 ]; then
									HOST_TLSA="_25._tcp.${DOMAIN}."
									HOST_TLSA_VAL="3 1 1 ${TLSA_HASH_SHA256_PUBEXIM}"
									DOM256="_25._tcp.${MXREC} 300 IN TLSA 3 1 1 ${TLSA_HASH_SHA256_PUBEXIM}"
									echo "action=dns&do=delete&domain=${DOMAIN}&type=TLSA&name=${HOST_TLSA}" >> ${TASK_QUEUE}
									run_dataskq
									echo "action=dns&do=add&domain=${DOMAIN}&type=TLSA&name=${HOST_TLSA}&value=${HOST_TLSA_VAL}&ttl=300&named_reload=yes" >> ${TASK_QUEUE}
									run_dataskq
									GENERATED=1
								fi
								MXREC=""
								MXREC=`echo "$LINE"|awk '{print $NF}'`
								LASTCHAR=""
								LASTCHAR=`echo -n "$MXREC"|tail -c 1`
								if [ "$LASTCHAR" != "." ]; then
									MXREC="${MXREC}.${DOMAIN}"
								fi
								HOST_TLSA="_25._tcp.${MXREC}"
								HOST_TLSA_VAL="3 1 1 ${TLSA_HASH_SHA256_PUBEXIM}"
								DOM256="_25._tcp.${MXREC} 300 IN TLSA 3 1 1 ${TLSA_HASH_SHA256_PUBEXIM}"
								echo "action=dns&do=delete&domain=${DOMAIN}&type=TLSA&name=${HOST_TLSA}" >> ${TASK_QUEUE}
								run_dataskq
								echo "action=dns&do=add&domain=${DOMAIN}&type=TLSA&name=${HOST_TLSA}&value=${HOST_TLSA_VAL}&ttl=300&named_reload=yes" >> ${TASK_QUEUE}
								run_dataskq
								GENERATED=1
							fi
						done < "${NAMEDDIR}/${DOMAIN}.db"
					fi
				fi
			fi
			if [ ${GENERATED} -ne 1 ]; then
				echo 4
			else
				echo 0
			fi
		fi
	fi
}

RETTLSA=`try_gen_tlsa`

if [ $RETTLSA -ne 0 ]
then
	echo "TLSA gen failed"
	case "$RETTLSA" in
		1)
			echo "No directadmin binary found."
		        ;;
		2)
		    echo "TLSA not enabled in directadmin.conf"
		        ;;
		*)
			echo "Unexpected problem: no domain of specified type found, exim cert doesn't exist, or domain doesn't have MX records.."
			;;
		esac
	exit $RETTLSA
else
	echo "TLSA gen succeeded"
fi

exit 0