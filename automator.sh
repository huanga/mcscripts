#! /bin/bash

# run-queue.sh will execute the pending queue of commands issued via web interface

SERVER_SCREEN="minecraft"
QUEUE_FILE="/home/minecraft/public_html/adm_queue.txt"
LOCK_FILE="/home/minecraft/public_html/adm_queue.lock"
QUIT_FILE="/home/minecraft/public_html/adm_queue.quit"

function run_queue {
	if [ -f $LOCK_FILE ]
	then
		echo "A session is already running. Do nothing. (This should never happen)"	
	else
		# Lock to prevent multi-runs
		touch $LOCK_FILE
		cat $QUEUE_FILE | while read LINE
		do
			screen -x $SERVER_SCREEN -X stuff "`printf "$LINE\r"`"
			printf '%s\n' "[$(date -u '+%F %T')] Running command: $LINE"
		done

		# Empty the queue
		cat /dev/null > $QUEUE_FILE
		rm $LOCK_FILE
	fi
}

RUNQUEUES=1
while [ $RUNQUEUES ]; do
	[ -f "$QUIT_FILE" ] && RUNQUEUES=0
	run_queue
	sleep 5
done
rm -f $QUIT_FILE
