#! /bin/bash

# Minecraft Scheduled Incremental Backup Script
#   Originally Written: Andy Huang { huang_a }, 2011-09-29
#
# This script may be redistributed free of charge with or without edits,
# as long as this original copyright and this comment block remain in tact
# with one VERY important exception:
#
# This script MUST NEVER be released under GPL, LGPL, or alike license
# terms. I absolutely despise GPL and its varients. Do not be confused, GPL
# IS communism, and it is NOT welcomed for my scripts. For interesting side
# reading, consider this article (copy URL starts with http, and ends with
# html, with no linbreak, spaces, or # in the URL:
# http://jurajsipos.articlesbase.com/operating-systems-articles/stop-linux-
# communism-3747668.html
#
# If you must redistribute under some form of license agreement, you MUST
# add this block as addendum to your license agreement.
#
# Together, we can stop software communism!
#

# Change Log
# ============================================================================
# 1.0.1 (2011-10-09)
# * Fixed issue where saving would not be toggled if notification is off
#
# 1.0.0	(2011-09-29)
# * Initial Release

# Configure these configuration settings
declare -a SERVER_DIRS=(/dev/shm/minecraft/bukkit100)

# Where would you like the LOCAL backup to be saved?
# Note: for now, all backups are saved in the same folder; eventually I should
# make this optional configurable for different location per server.
LOCAL_BACKUP_LOCATION="/home/minecraft/backup/"

# How long would you like to keep LOCAL backups? Default 2 weeks
#
# Example 1 Day
# LOCAL_BACKUP_RETAIN_DURATION="1D"
# Example 2 Weeks
# LOCAL_BACKUP_RETAIN_DURATION="2W"
LOCAL_BACKUP_RETAIN_DURATION="1W"

# Optional: Where would you like the REMOTE backup to be saved? Leave this
# blank if you do not want to backup on a different server. Note: Remote
# server MUST have rdiff-backup installed as well.
#
# Example (do not backup remotely):
# REMOTE_BACKUP_LOCATION=""
# Example (backup to remote.server's /home/user/backups/ login with user):
REMOTE_BACKUP_LOCATION="user@remote.server::/home/user/backups/"

# How long would you like to keep REMOTE backups? Default 4 weeks
#
# Example 1 Day
# REMOTE_BACKUP_RETAIN_DURATION="1D"
# Example 2 Weeks
# REMOTE_BACKUP_RETAIN_DURATION="2W"
REMOTE_BACKUP_RETAIN_DURATION="2W"

# Optional: Set only if you want to be notified OR trigger a save before
# backing up the server. They appear in same order as SERVER_DIRS. Assumes
# that you run the server in a screen with specified name via commands such
# as these: (yours may, of course, be different)
# screen -dmS minecraft
# screen -x minecraft -X stuff "`printf "./launch_server.sh\r"`"
declare -a SERVER_SCREENS=(minecraft)

# Save before backing up? 0 = No, 1 = Yes; if enabled, you MUST set
# SERVER_SCREENS variable.
SAVE_BEFORE_BACKUP=1

# Notify backup status? 0 = No, 1 = Light, 2 = Full; if enabled, you MUST set
# SERVER_SCREENS variable.
NOTIFY_BACKUP=1

# Debug?
DEBUG_MODE=1

# Do not edit below this line
# ---------------------------------------------------------------------------

# Verify requirements
echo "===================="
echo "Checking pre-reqs..."
echo "===================="

if [ $SAVE_BEFORE_BACKUP -eq 1 ]; then
	declare -a REQ_CMDS=(screen rdiff-backup)
else
	declare -a REQ_CMDS=(rdiff-backup)
fi

numREQ_CMDS=${#REQ_CMDS[@]}
for ((i=0;i<$numREQ_CMDS;i++)); do
	if which ${REQ_CMDS[$i]} &> /dev/null; then
		if [ $DEBUG_MODE -eq 1 ]
		then
			echo "[PASS] ${REQ_CMDS[$i]} is available."
		fi
	else
		echo "[FAIL] ${REQ_CMDS[$i]} is not installed on your system. Scheduled Incremental Backup Script cannot be used without ${REQ_CMDS[$i]}."
		exit 1
	fi
done

# Iterate through worlds for backup
numSERVER_DIRS=${#SERVER_DIRS[@]}
for ((i=0;i<$numSERVER_DIRS;i++)); do
	if [ $NOTIFY_BACKUP -gt 1 ]
	then
		# Notify that we are running a backup now
		screen -x ${SERVER_SCREENS[$i]} -X stuff "`printf "say [Auto] Backing up server...\r"`"
	fi

	if [ $DEBUG_MODE -eq 1 ]
	then
		echo "[INFO] Backing up ${SERVER_DIRS[$i]}."
	fi

	# Save world before backing up
	if [ $SAVE_BEFORE_BACKUP -eq 1 ]
	then
		if [ $NOTIFY_BACKUP -gt 1 ]
		then
			screen -x ${SERVER_SCREENS[$i]} -X stuff "`printf "say [Auto] Saving world...\r"`"
		fi
		screen -x ${SERVER_SCREENS[$i]} -X stuff "`printf "save-off\r"`"
		screen -x ${SERVER_SCREENS[$i]} -X stuff "`printf "save-all\r"`"
	fi

	# Local backup & cleanup
	if [ $DEBUG_MODE -eq 1 ]
	then
		echo "[INFO] Making local backup."
	fi
	rdiff-backup ${SERVER_DIRS[$i]} $LOCAL_BACKUP_LOCATION/${SERVER_DIRS[$i]}
	if [ $DEBUG_MODE -eq 1 ]
	then
		echo "[INFO] Perform local cleanup."
	fi
	rdiff-backup --remove-older-than $LOCAL_BACKUP_RETAIN_DURATION --force $LOCAL_BACKUP_LOCATION/${SERVER_DIRS[$i]}

	if [ ! -z $REMOTE_BACKUP_LOCATION ]
	then
		if [ $DEBUG_MODE -eq 1 ]
		then
			echo "[INFO] Making remote backup."
		fi
		rdiff-backup ${SERVER_DIRS[$i]} $REMOTE_BACKUP_LOCATION/${SERVER_DIRS[$i]}
		if [ $DEBUG_MODE -eq 1 ]
		then
			echo "[INFO] Perform remote cleanup."
		fi
		rdiff-backup --remove-older-than $REMOTE_BACKUP_RETAIN_DURATION --force $REMOTE_BACKUP_LOCATION/${SERVER_DIRS[$i]}
	fi

	if [ $SAVE_BEFORE_BACKUP -eq 1 ]
	then
		screen -x ${SERVER_SCREENS[$i]} -X stuff "`printf "save-on\r"`"
		screen -x ${SERVER_SCREENS[$i]} -X stuff "`printf "save-all\r"`"
	fi

	if [ $NOTIFY_BACKUP -ge 1 ]
	then
		screen -x ${SERVER_SCREENS[$i]} -X stuff "`printf "say [Auto] Backup complete.\r"`"
	fi
done
