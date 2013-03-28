#! /bin/bash

##
# Bad Behaviour Bans
# -------------------
# Author: Andy Huang { mc: huang_a @ mc.chiisana.net (not an email); r: /u/chiisana; t: @AndyHuang  }
# Scans server.log file and automatically bans users with excessive amount of "Protocol error" disconnects,
# as well as checks for invalid username attacks. Since there is a large amount of IP addreses, the invalid
# username attack part will be fairly slow. Be sure to configure the script correctly, and create new
# server.log files accordingly. If you do not do this, you WILL ban innocent people, and I will NOT provide
# any support in helping you unban people.

# NO WARRANTY OF ANY SORTS, IMPLIED OR SPECIFIED. IF I SAY I WILL PROVIDE WARRANTY, I AM PROBABLY DRUNK
# AND AM NOT BE TAKEN SERIOUSLY!

# How many occurances before ban? (Default: 10)
THRESHOLD_BEFORE_BAN=10

# Ban TOR exit points or other known abuse sources? (0: No | 1: Yes)
DNSBL_BAN=1

# List of DNSBL to use. Uncomment (remove the #) for others if you want to check against them. You should
# be careful, as some of them might list dynamic IP addresses (e.g.: dial-up internet) as potential bad IP 
# address, so legitimate users may be banned. The last one, dnsbl.tornevall.org, will only list tor exit
# points, which are usually safe to ban.
BLISTS="
#	cbl.abuseat.org
#	dnsbl.sorbs.net
#	bl.spamcop.net
#	zen.spamhaus.org
#	combined.njabl.org
	dnsbl.tornevall.org
"

# -----------------------------------------------------
# To automatically ban people, set this variable to: 42
# -----------------------------------------------------
# Anything else, the script will only output the ban
# command for you to manually issue the command.
# -----------------------------------------------------
WHAT_IS_THE_ANSWER_TO_LIFE=0

# --------------------------------------
# Do NOT touch anything after this line.
# --------------------------------------
PEB_TMP=".peb.tmp"    # Protocol Error Ban temp list
DNS_TMP=".dnsbl.tmp"  # DNSBL temp list

function ban_ip {
	# Delete any pre-existing record before adding to ban list
	iptables -D INPUT -s $1 -j DROP
	iptables -A INPUT -s $1 -j DROP
}

function show_ban_command {
	echo "iptables -D INPUT -s $1 -j DROP"
	echo "iptables -A INPUT -s $1 -j DROP"
}

# Generate an updated list of "Protocol error" counts and IP addresses from our current log file
grep "Protocol error" server.log | awk '{print $5}' | egrep -Z "[0-9]*\:[0-9]{5}" | sed 's/\:[0-9]*//g' | sed 's/\///g' | uniq -c | sort -nr > $PEB_TMP

cat $PEB_TMP |
while read line
do
	COUNTS=`echo "$line"|awk '{print $1}'`
	IP=`echo "$line"|awk '{print $2}'`
	if [ $COUNTS -gt $THRESHOLD_BEFORE_BAN ];then
		if [ $WHAT_IS_THE_ANSWER_TO_LIFE -eq 42 ];then
			echo "# Banning $IP for $COUNTS violations."
			ban_ip $IP
		else
			echo "# $IP should be banned for $COUNTS violations."
			show_ban_command $IP
		fi
	fi
done
rm $PEB_TMP

# Generate an updated list of "Outdated client" counts and IP addresses fro our current log file
grep "Outdated client" server.log | awk '{print $6}' | egrep -Z "[0-9]*\:[0-9]{5}" | sed 's/\:[0-9]*//g' | sed 's/\[\///g' | sed 's/\]//g' | sort | uniq -dc | sort -nr > $DNS_TMP

if [ $DNSBL_BAN -eq 1 ]; then
	cat $DNS_TMP |
	while read line
	do
		IP=`echo "$line"|awk '{print $2}'`
		reverse=$(echo $IP | sed -ne "s~^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)$~\4.\3.\2.\1~p")
		COUNTER=0
		for BL in ${BLISTS}; do
			LISTED="$(dig +short -t a ${reverse}.${BL}. | tr -d ' ')"
			if  [ -n "$LISTED" ]; then
				COUNTER=$((COUNTER+1))
			fi
		done

		if [ $COUNTER -gt 0 ]; then
			if [ $WHAT_IS_THE_ANSWER_TO_LIFE -eq 42 ];then
				echo "# Banning $IP for being on $COUNTER black lists"
				ban_ip $IP
			else
				echo "# $IP should be banned for being on $COUNTER black lists"
				show_ban_command $IP
			fi
		fi
	done
	rm $DNS_TMP
fi
