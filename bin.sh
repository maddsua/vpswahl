#!/bin/bash

set -e

dbfile=~/.ssh/remote_registry.db3

if ! command -v sqlite3 &> /dev/null
then
    echo "ERR: sqlite3 is not installed"
	echo "HINT: 'sudo apt install sqlite3'"
	exit 1
fi

schema=$(cat <<EOF
create table if not exists remotes (
	name text primary key,
	host text not null,
	user text,
	port integer,
	id_key text
);
EOF
)

sqlite3 $dbfile "$schema"

mapfile -t entries < <(sqlite3 $dbfile "select name, host, user, port, id_key from remotes order by name asc")

if [ "${#entries[@]}" -eq 0 ]; then
    echo "WARN: No DB entries at '$dbfile'"
    exit 0
fi

selectedIdx=0

gencmd() {

	IFS='|' read -r _name host user port id_key <<< "$1"

	args=""

	if [ -n "$id_key" ]; then
		args+=" -i $id_key"
	fi

	if [ -n "$port" ]; then
		args+=" -p $port"
	fi

	if [ -n "$user" ]; then
		args+=" $user"
	else
		args+=" $(whoami)"
	fi

	echo "ssh$args@$host"
}

render() {

	clear

	printf "%-30s %-20s %-8s %-15s %-20s\n" "Name" "Host" "Port" "User" "Key File"
    echo "----------------------------------------------------------------------------------------------"

	for (( idx=0; idx<${#entries[@]}; idx++ )); do

		entry=${entries[$idx]}

		IFS='|' read -r name host user port id_key <<< "$entry"

		if [ "$idx" -eq "$selectedIdx" ]; then
            printf "\e[7m-> %-30s %-20s %-8s %-15s %-20s \e[0m\n" "$name" "$host" "$port" "$user" "$id_key"
        else
            printf " %-30s %-20s %-8s %-15s %-20s \n" "$name" "$host" "$port" "$user" "$id_key"
        fi
	done

	echo "----------------------------------------------------------------------------------------------"
    echo "Select a connection and press Enter"
}

render

incr() {

	local next=$((selectedIdx + 1))

	if [ $next -ge "${#entries[@]}" ]; then
		selectedIdx=0
	else
		selectedIdx=$next
	fi
}

decr() {

	local next=$((selectedIdx - 1))

	if [ "0" -gt $next ]; then
		selectedIdx=$((${#entries[@]} - 1))
	else
		selectedIdx=$next
	fi
}

while true; do

    read -rsn1 input
    
    case "$input" in

        # Up arrow key
        $'\x1b' )

            read -rsn2 -t 0.1 input
            if [ "$input" == "[A" ]; then
				decr
            elif [ "$input" == "[B" ]; then
				incr
            fi

			render

            ;;

        # Enter key
        $'' )

			clear

			entry=${entries[$selectedIdx]}
			sshcmd=$(gencmd $entry)

			IFS='|' read -r name _ <<< "$entry"

			echo "Connecting to: $name"
			echo "--------"
			echo "$sshcmd"

			exec $sshcmd

            ;;
    esac
done
