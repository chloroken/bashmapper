#!/bin/bash

# TODO
# - Add multiple undo steps
# - Add multiflagging
# - Change map <sig> <jcode> to
# - map fetch <jcode> (current system)

# [COMMAND]					[BEHAVIOR]
# map add					additively paste sigs
# map lazy					'lazy-delete' paste
# map undo					revert last command
#
# [NAVIGATION]				[BEHAVIOR]
# map up 					navigate up
# map top 					navigate to home system
# map nav <sig> <sig>.. 	navigate down one or more wormholes
# map full 					show full map
#
# [SIGNATURES]				[BEHAVIOR]
# map <sig> <label>			rename a sig (accepts multiple words)
# map <sig> flag			append "!" to ID (e.g., "ABC!")
# map <sig> <jcode>			append class/statics/weather to label
# map del <sig> <sig>..		remove one or more signatures

# Initialize magic variables
dir="$HOME/Documents/bashmapper"
top="$dir/top/"
backup="$dir/undo/"
clipboard="$dir/clipboard.txt"
del="$dir/del.txt"
divider="=============================="

# Ensure map root directory exists
if [ ! -d "$dir/top/" ]; then
    mkdir "$dir/top/"
fi

# Undo functionality
if [[ "$1" == "undo" ]]; then
	rm -rf "$top"
	cp -r "$backup" "$top"
	cd "$top"
else
	rm -rf "$backup"
	cp -r "$top" "$backup"
fi

# Reset map view ("map top")
if [[ "$1" == "top" ]]; then
	cd "$top"

# Navigate up ("map up")
elif [[ "$1" == "up" && "${PWD##*/}" != "top" ]]; then
	cd ".."

# Multi-sig commands ("map <cmd> <sig> <sig>..")
elif [[ "$1" == "nav" || "$1" == "del" ]]; then
	for param in "$@"; do

		# Ensure we're looking at sig IDs (e.g., "ABC")
		letters='^[a-zA-Z]+$'
		if [[ "${#param}" -eq 3  && "${param}" =~ $letters ]]; then
			filename=$(find . -maxdepth 1 -iname "${param}*")

			# Navigate wormholes ("map nav <sig> <sig>..")
			if [[ "$1" == "nav" ]]; then
				cd "$filename"

			# Delete signatures ("map del <sig> <sig>..")
			elif [[ "$1" == "del" ]]; then
				rm -rf "$filename"
			fi
		fi
	done

# Paste signatures from clipboard ("map add")
elif [[ "$1" == "add" || "$1" == "lazy" ]]; then
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
		newText=$(echo "${head} ${tailReal}" | sed -e 's/Cosmic Signature //' -e 's/Unstable Wormhole//' -e 's/Wormhole//' -e 's/Gas Site //')

		# Remove more bits from data/relic sites, but only when they're revealed
		# This allows for half-scanned stuff to show "Data Site" still, etc
		if [[ "$newText" == *"Unsecured"* || "$newText" == *"Forgotten"* || "$newText" == *"Ruined"* || "$newText" == *"Central"* ]] ; then
			newText=$(echo "${newText}" | sed -e 's/Data Site //' -e 's/Relic Site //')
		fi
		
		# Signature 'overwriting' (i.e., which to keep) functionality is
		# done by comparing string lengths (somehow this actually works)
		checkExisting=$(find . -maxdepth 1 -name "${head}*")
		if [[ ${#checkExisting} -lt ${#newText} ]]; then
			if [[ ${#checkExisting} -gt 0 ]]; then
				mv "$checkExisting" "$newText"
			else
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

# Labeling commands
elif [[ "${#1}" -eq 3 ]]; then
	filename=$(find . -maxdepth 1 -iname "${1}*")

	# Flag a signature with "!" (map flag <sig>)
	if [[ "$2" == "flag" ]]; then
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

	# Naming commands
	else
		id=$(echo "$filename" | cut -c1-5)
		tempname=$(echo "$id" "$2")
		re='^[0-9]+$'
		
		# Auto-label signatures ("map <sig> <jcode>")
		if [[ "${#2}" -eq 6 && "$2" =~ $re ]]; then # jcodes are 6-digit integers
			
			# Append class, static, and weather strings
			newname=$(grep -hr "$2" "$dir/data.txt")
			mv "$filename" "$filename $newname"
			cd "$filename $newname"
				
		# Simple relabel ("map <sig> <label>")
		elif [[ $# -eq 2 ]]; then
			mv "$filename" "$tempname"

		# Complex relabel ("map <sig> <label> <label>..")
		elif [[ $# -gt 2 ]]; then
			paramStrings=""
			i=1
			for param in "$@"; do
				if ((i>2)); then
					paramStrings="${paramStrings}$param "
				fi
				((i++))
			done
			mv "$filename" "$tempname $paramStrings"
		fi
	fi
fi

# Print updated map
clear
echo $divider
echo "CURRENT LOCATION: ${PWD##*/}"
echo $divider
if [[ "$1" == "full" ]]; then
	cd "$top"
	tree -C | tail -n+2 - | head -n -2
else
	tree -LC 1 | tail -n+2 - | head -n -2
fi

# Indicate signatures for manual removal
if [[ -s "$dir/del.txt" ]]; then
	echo $divider
	echo "OBSOLETE SIGNATURES:"
	while read line; do
		echo "> $line"
	done < "$del"
	echo $divider

	#Clean up
	rm "$del"
fi
