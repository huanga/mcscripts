#! /bin/sh
# Some configurations
declare -a worlds=(world)
pigmap="/home/minecraft/mcscripts/pigmap"
i_path_base="/home/minecraft/mcserver/bukkit"
o_path_base="/home/minecraft/public_html/maps"
g_path="/home/minecraft/mcscripts/images"
b_param=6
t_param=1
z_param=10
h_param=2

# if for whatever reason you want to set a working path, script will cd to it first
working_path="/home/minecraft/mcserver/bukkit"

# Don't touch anything else down here
# Switch to working directory as needed
if [ ! -z "$working_path" ]
	then
		cd $working_path
fi

# Make sure we don't double run and pwn CPU completely, that would not be good.
if [ "$(ps aux|egrep -v 'grep|pigmap.sh|pigmap-19.sh'|egrep 'pigmap')" ]
	then
		echo Running process found, exiting
		exit 0
fi

numworlds=${#worlds[@]}
for ((i=0;i<$numworlds;i++)); do
	# Verify if we have had previous runs
	if [ -e .${worlds[$i]}-pigmap-lastsuccess ]
		then
			# Incremental Build
			for filename in $i_path_base/${worlds[$i]}/region/*
			do
				if [ $filename -nt $working_path/.${worlds[$i]}-pigmap-lastsuccess ]
					then
						# this file is newer!
						echo $filename requires rendering!
						echo $filename >> regionlist
				fi
			done
			# Issue the incremental build command
			$pigmap -i $i_path_base/${worlds[$i]} -o $o_path_base/${worlds[$i]} -r regionlist -g $g_path -h $h_param -x
		else
			# Initial Build
			$pigmap -B $b_param -T $t_param -Z $z_param -i $i_path_base/${worlds[$i]} -o $o_path_base/${worlds[$i]} -g $g_path -h $h_param
	fi

	# DONE! Remove regionlist (for next run) and touch .pigmap-lastsuccess
	rm regionlist
	touch $working_path/.${worlds[$i]}-pigmap-lastsuccess
done

