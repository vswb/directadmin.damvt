#!/bin/sh

FTPLS=/usr/bin/ncftpls
CURL=/usr/local/bin/curl
if [ ! -e ${CURL} ]; then
	CURL=/usr/bin/curl
fi
TMPDIR=/home/tmp
PORT=${ftp_port}
FTPS=0
if [ "${ftp_secure}" = "ftps" ]; then
	FTPS=1
fi

SSL_REQD=""
if ${CURL} --help | grep -m1 -q 'ftp-ssl-reqd'; then
    SSL_REQD="--ftp-ssl-reqd"
elif ${CURL} --help | grep -m1 -q 'ssl-reqd'; then
    SSL_REQD="--ssl-reqd"
fi

if [ "$PORT" = "" ]; then
	PORT=21
fi

RANDNUM=`/usr/local/bin/php -r 'echo rand(0,10000);'`
#we need some level of uniqueness, this is an unlikely fallback.
if [ "$RANDNUM" = "" ]; then
        RANDNUM=$ftp_ip;
fi

CFG=$TMPDIR/$RANDNUM.cfg
rm -f $CFG
touch $CFG
chmod 600 $CFG

DUMP=$TMPDIR/$RANDNUM.dump
rm -f $DUMP
touch $DUMP
chmod 600 $DUMP

#######################################################
# FTP
list_files()
{
	if [ ! -e $FTPLS ]; then
		echo "";
		echo "*** Unable to get list ***";
		echo "Please install $FTPLS by running:";
		echo "";
		echo "cd /usr/local/directadmin/scripts";
		echo "./ncftp.sh";
		echo "";
		exit 10;
	fi

	#man ncftpls lists:
	#If you want to use absolute pathnames, you need to include a literal slash, using the "%2F" code for a "/" character.
	#use expr to replace /path to /%2Fpath, if needed.
	CHAR1=`echo ${ftp_path} | awk '{print substr($1,1,1)}'`
	if [ "$CHAR1" = "/" ]; then
		new_path="/%2F`echo ${ftp_path} | awk '{print substr($1,1)}'`"
		ftp_path=${new_path}
	else
		ftp_path="/${ftp_path}"
	fi

	echo "host $ftp_ip" >> $CFG
	echo "user $ftp_username" >> $CFG
	echo "pass $ftp_password" >> $CFG

	if [ ! -s $CFG ]; then
		echo "ftp config file $CFG is 0 bytes.  Make sure $TMPDIR is chmod 1777 and that this is enough disk space.";
		echo "running as: `id`";
		df -h
		exit 11;
	fi

	$FTPLS -l -f $CFG -P ${PORT} -r 1 -t 10 "ftp://${ftp_ip}${ftp_path}" > $DUMP 2>&1
	RET=$?

	if [ "$RET" -ne 0 ]; then
		cat $DUMP

		if [ "$RET" -eq 3 ]; then
			echo "Transfer failed. Check the path value. (error=$RET)";
		else
			echo "${FTPLS} returned error code $RET";
		fi

	else
		COLS=`awk '{print NF; exit}' $DUMP`
		cat $DUMP | grep -v -e '^d' | awk "{ print \$${COLS}; }"
	fi
}

#######################################################
# FTPS
list_files_ftps()
{
	if [ ! -e ${CURL} ]; then
		echo "";
		echo "*** Unable to get list ***";
		echo "Please install curl by running:";
		echo "";
		echo "cd /usr/local/directadmin/custombuild";
		echo "./build curl";
		echo "";
		exit 10;
	fi

	#double leading slash required, because the first one doesn't count.
	#2nd leading slash makes the path absolute, in case the login is not chrooted.
	#without double forward slashes, the path is relative to the login location, which might not be correct.
	ftp_path="/${ftp_path}"

	/bin/echo "user =  \"$ftp_username:$ftp_password\"" >> $CFG

	${CURL} --config ${CFG} ${SSL_REQD} -k --silent --show-error ftp://$ftp_ip:${PORT}$ftp_path/ > ${DUMP} 2>&1
	RET=$?

	if [ "$RET" -ne 0 ]; then
		echo "${CURL} returned error code $RET";
		cat $DUMP
	else
		COLS=`awk '{print NF; exit}' $DUMP`
		cat $DUMP | grep -v -e '^d' | awk "{ print \$${COLS}; }"
	fi
}


#######################################################
# Start

if [ "${FTPS}" = "1" ]; then
	list_files_ftps
else
	list_files
fi


rm -f $CFG
rm -f $DUMP

exit $RET
