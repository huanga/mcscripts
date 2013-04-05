#!/bin/bash
### Allow only traffic from ITALY (it). Use ISO code separate by space to allow other countries ###
ISO="it"

#example to allow Italy (it), Canada (ca), and Taiwan (tw)
#ISO="it ca tw"

### Set PATH ###
IPT=/sbin/iptables
WGET=/usr/bin/wget
EGREP=/bin/egrep

### Safety: Your own IP address should _never_ be blocked!
OWNIP="75.157.10.120"

### No editing below ###
COUNTRYLIST="allowed-countries-ips"
ZONEROOT="/root/iptables"
DLROOT="http://www.ipdeny.com/ipblocks/data/countries"

cleanOldRules(){
$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X
$IPT -P INPUT ACCEPT
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD ACCEPT
}

# create a dir
[ ! -d $ZONEROOT ] && /bin/mkdir -p $ZONEROOT

# clean old rules
cleanOldRules

# create a new iptables list
$IPT -N $COUNTRYLIST

for c  in $ISO
do
	# local zone file
	tDB=$ZONEROOT/$c.zone

	# get fresh zone file
	$WGET -O $tDB $DLROOT/$c.zone

	# country specific log message
#	COUNTRYACCEPTMSG="$c Country Accept"

	# get 
	COUNTRYIP=$(egrep -v "^#|^$" $tDB)
	for ipblock in $COUNTRYIP
	do
#	   $IPT -A $COUNTRYLIST -s $ipblock -j LOG --log-prefix "$COUNTRYACCEPTMSG"
	   $IPT -A $COUNTRYLIST -s $ipblock -j ACCEPT
	done
done

# Allow own IP address to have access
$IPT -A $COUNTRYLIST -s $OWNIP -j ACCEPT

# Drop everything else
$IPT -A $COUNTRYLIST -j DROP

# Drop everything
#$IPT -I INPUT -j $COUNTRYLIST
#$IPT -I OUTPUT -j $COUNTRYLIST
#$IPT -I FORWARD -j $COUNTRYLIST

# Join the rules so only monitor minecraft port
$IPT -A INPUT -p tcp -m tcp --dport 25565 -j $COUNTRYLIST

# call your other iptable script
# /path/to/other/iptables.sh

exit 0
