#!/usr/bin/env bash
set -eu

# [COMMAND]					[BEHAVIOR]
# map add					additively paste sigs
# map lazy					'lazy-delete' paste
# map undo					revert last command (3 step max)
#
# [NAVIGATION]				[BEHAVIOR]
# map up 					navigate up
# map top 					navigate to home system
# map nav <sig> <sig>.. 	navigate down one or more wormholes
# map full 					show full map
# map paths					show only wormholes
# map gas					show only wormholes & gas
#
# [SIGNATURES]				[BEHAVIOR]
# map <sig> <label>			rename a sig (accepts multiple words)
# map flag <sig> <sig>..	append "!" to one or more signatures
# map <sig> <jcode>			append class/statics/weather to label
# map del <sig> <sig>..		remove one or more signatures

# Setup core directory variables
dir="$HOME/Documents/bashmapper"
top="$dir/top"
backup1="$dir/undo1/"
backup2="$dir/undo2/"
backup3="$dir/undo3/"

# Ensure map root directory and all subdirectories exist
mkdir -p "$top"

# Setup current location tracker
cur_loc="$dir/current-location.txt"
if ! [ -f "$cur_loc" ]; then
	echo "$top" > "$cur_loc"
fi
cd "$(cat "$cur_loc")"

# Initialize magic variables
clipboard="$dir/clipboard.txt"
del="$dir/del.txt"
new="$dir/new.txt"
divider="=============================="

undo() {
	if [ ! -z "$(ls -A $backup1)" ]; then
		rm -rf "$top"
		cp -r "$backup1" "$top"
		rm -rf "$backup1"
		cp -r "$backup2" "$backup1"
		rm -rf "$backup2"
		cp -r "$backup3" "$backup2"
		rm -rf "$backup3"
		cd "$top"
	fi
}

backup() {
	rm -rf "$backup3"
	cp -r "$backup2" "$backup3"
	rm -rf "$backup2"
	cp -r "$backup1" "$backup2"
	rm -rf "$backup1"
	cp -r "$top" "$backup1"
}

nav() {
	cd "$1"
	if ! $(pwd | grep -q "$top"); then
		echo "Error: '$1' took us out of the directory structure (pwd:'$(pwd)')"
		exit -1
	fi
	pwd > "$cur_loc"
}

is_sig() {
	# Sig IDs are 3 
	# Ensure we're looking at sig IDs (e.g., "ABC")
	letters='^[a-zA-Z]+$'
	if [[ "${#1}" -eq 3  && "$1" =~ $letters ]]; then
		return 0
	else
		return 1
	fi
}

cur_system() {
	tree -LC 1 | tail -n+2 - | head -n -2
}

cur_loc_string() {
	echo $divider
	echo "CURRENT LOCATION: ${PWD##*/}"
	echo $divider
}

cur_system_string() {
	clear
	cur_loc_string
	cur_system
}

full_map() {
	cd "$top"
	tree -C | tail -n+2 - | head -n -2
}

sig_full_filename() {
	find . -maxdepth 1 -iname "${1}*"
}

flag() {
	echo "multiflagging"
	filename="$(sig_full_filename "$1")"
	preString="$filename"
	for (( i=0; i<${#preString}; i++ )); do
		if [[ "${preString:$i:1}" == " " ]]; then
			if [[ $i -ge 1 ]]; then
				break
			fi
		fi
	done
	postString="${preString:0:$i}!${preString:$i}"
	mv "$filename" "$postString"
}

add_from_clipboard() {
	wl-paste | sed -e "s/[[:space:]]\+/ /g" | tr -s ' ' > "$clipboard"
	cat "$clipboard" | while read -r line || [ -n "$line" ]; do

		# Initial parsing of clipboard (keep chars #1-3 and #9+)
		head=$(echo "$line" | cut -c1-3)
		tail=$(echo "$line" | cut -c 9-)
		
		# Jspace sites don't have numbers, so we can just
		# trim when we find the first integer in the string
		nums='^[0-9]+$'
		for (( i=0; i<${#tail}; i++ )); do
			if [[ "${tail:$i:1}" =~ $nums ]] ; then
				break
			fi
		done

		# Concatenate new string and remove irrelevant bits
		tailReal=$(echo "$tail" | cut -c1-"$i")
		newText=$(echo "${head} ${tailReal}" | sed -e 's/Cosmic Signature //' -e 's/Unstable Wormhole //' -e 's/Wormhole //' -e 's/Gas Site //' -e 's/Data Site /—Data—/' -e 's/Relic Site /—Relic—/')

		newText=$(echo "${newText}" | sed -e 's/Perimeter Amplifier//' -e 's/Perimeter Information Center//' -e 's/Perimeter Comms Relay//' -e 's/Perimeter Transponder Farm//' -e 's/Frontier Database//' -e 's/Frontier Receiver//' -e 's/Frontier Digital Nexus//' -e 's/Frontier Trinary Hub//' -e 's/Frontier Enclave Relay//' -e 's/Frontier Server Bank//' -e 's/Core Backup Array//' -e 's/Core Emergence//' -e 's/Perimeter Coronation Platform//'  -e 's/Perimeter Power Array//' -e 's/Perimeter Gateway//' -e 's/Perimeter Habitation Coils//' -e 's/Frontier Quarantine Outpost//' -e 's/Frontier Recursive Depot//' -e 's/Frontier Conversion Module//' -e 's/Frontier Evacuation Center//' -e 's/Core Data Field//' -e 's/Core Information Pen//' -e 's/Core Assembly Hall//' -e 's/Core Circuitry Disassembler//')
		
		# Remove more bits from data/relic sites, but only when they're revealed
		# This allows for half-scanned stuff to show "Data Site" still, etc
		# This section is a mess and needs a complete refactor
		if [[ "$newText" == *"Unsecured"* || "$newText" == *"Forgotten"* || "$newText" == *"Ruined"* || "$newText" == *"Central"* || "$newText" == *"Crimson"* || "$newText" == *"Tetrimon"* || "$newText" == *"Reservoir"* ]] ; then
			newText=$(echo "${newText}" | sed -e 's/—Data—//' -e 's/—Relic—//' -e 's/—Gas Site—//' -e 's/Perimeter //' -e 's/Frontier //' -e 's/Core //' -e 's/Reservoir/</')
			newText=$(echo "${newText}" | sed -e 's/Unsecured/—Combat—/' -e 's/Forgotten/—Combat—/')
			newText=$(echo "${newText}" | sed -e 's/Ruined/—Relic—/' -e 's/Central/—Data—/' -e 's/Sparking Transmitter//' -e 's/Survey Site//' -e 's/Command Center//' -e 's/Data Mining Site//' -e 's/Monument Site//' -e 's/Temple Site//' -e 's/Science Outpost//' -e 's/Crystal Quarry//' -e 's/Rogue Drone//')
			newText=$(echo "${newText}" | sed -e 's/Angel//' -e 's/Blood Raider//' -e 's/Guristas//' -e 's/Sansha//' -e 's/Serpentis//' -e 's/Rogue Drones//')
		fi
		if [[ "$newText" == *"AEGIS Secure Transfer Facility"* ]]; then
			newText=$(echo "${newText}" | sed -e 's/AEGIS Secure Transfer Facility/—Combat—/')
		fi
		# Signature 'overwriting' (i.e., which to keep) functionality is
		# done by comparing string lengths (somehow this actually works)
		checkExisting=$(find . -maxdepth 1 -name "${head}*")
		if [[ ${#checkExisting} -lt ${#newText} ]]; then
			if [[ ${#checkExisting} -gt 0 ]]; then
				mv "$checkExisting" "$newText"
			else
				touch "$new"
				echo "$head" >> "$new"
				mkdir "$newText"
			fi
		fi

		# 'Lazy delete' functionality ("map lazy")
		if [[ "$1" == "lazy" ]]; then
			touch "$del"
			for file in */; do
			
				# Delete sigs not on the clipboard
				head=$(echo "$file" | cut -c1-3)
				if ! grep -q "$head" "$clipboard"; then
					rm -rf "$file"

					# Store sig identifiers for report
					echo "$head" >> "$del"
				fi 
			done
		fi
	done
	rm "$clipboard"
}

label_sig() {
	filename=$(find . -maxdepth 1 -iname "${cur_command}*")
	label="$1"

	# Naming commands
	id=$(echo "$filename" | cut -c1-5)
	tempname=$(echo "$id" "$label")
	re='^[0-9]+$'
	
	# Auto-label signatures ("map <sig> <jcode>")
	if [[ "${#label}" -eq 6 && "$1" =~ $re ]]; then # jcodes are 6-digit integers
		
		# Append class, static, and weather strings
		newname=$(grep -hr "$1" "$dir/data.txt")
		mv "$filename" "$filename $newname"
		cd "$filename $newname"
			
	# Handles both Complex ("map <sig> <label> <label>..") and Simple relabel ("map <sig> <label>")
	else
		label=$(echo "$id" "$*")
		mv "$filename" "$label"
	fi
}

# If no commands given, print the current system
if [ "$#" -eq 0 ]; then
	cur_system_string
	exit 0
fi

# Record the current command and shift remaining arguments left
cur_command="$1"
shift

# Undo functionality (3 steps)
if [[ "$cur_command" == "undo" ]]; then
	undo
else
	backup
fi

# Process command
case "$cur_command" in
	"top")
		nav "$top"
		;;
	"up")
		nav "$(dirname $(pwd))"
		;;
	"nav")
		for param in "$@"; do
			if is_sig "$param"; then
				nav "$(sig_full_filename "$param")"
			fi
		done
		;;
	"del")
		for param in "$@"; do
			if is_sig "$param"; then
				rm -rf "$(sig_full_filename "$param")"
			fi
		done
		;;
	"flag")
		for param in "$@"; do
			if is_sig "$param"; then
				flag "$param"
			fi
		done
		;;
	"add"|"lazy")
		add_from_clipboard $cur_command
		;;
	"full")
		clear
		cur_loc_string
		full_map
		exit 0
		;;
	"paths")
		clear
		cur_loc_string
		full_map | grep "~"
		exit 0
		;;
	"gas")
		clear
		cur_loc_string
		full_map | grep "~\|<"
		exit 0
		;;
	*)
		if is_sig "$cur_command"; then
			label_sig "$*"
		fi
		;;
esac

cur_system_string

# Indicate signatures for manual removal
if [[ -s "$dir/del.txt" ]]; then
	echo $divider
	echo "DELETE SIGNATURES:"
	while read line; do
		echo "> $line"
	done < "$del"
	echo $divider

	#Clean up
	rm "$del"
fi

# Indicate signatures to scan (new)
if [[ -s "$dir/new.txt" ]]; then
	echo $divider
	echo "NEW SIGNATURES:"
	while read line; do
		echo "> $line"
	done < "$new"
	echo $divider

	#Clean up
	rm "$new"
fi
