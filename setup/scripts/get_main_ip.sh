#!/bin/sh
#Script to return the main useable device IP address of the box, used for main outbound connections.
#on a LAN, this should match your directadmin.conf lan_ip setting.
#for normal servers, this will likely return your license IP (usually)
#Will also be the default IP that exim sends email through.
OS=`uname`
if [ "${OS}" = "FreeBSD" ]; then
	/sbin/ifconfig | grep inet | grep -m1 broadcast | awk '{ print $2; }'
else
	/sbin/ip a | grep inet | grep -m1 brd | awk '{ print $2; };' | cut -d/ -f1
fi
RET=$?
exit $RET
