#!/bin/bash

# COMMAND					BEHAVIOR
#
# "map" 					paste signatures
# "map <sig> rm" 			remove a signature
#
# "map <sig>" 				navigate down
# "map up" 					navigate up
# "map root" / "map home" 	navigate to root of map
#
# "map <sig> <nickname>"	rename a signature
# "map <sig> <jcode>"		fetch class/statics/weather
# "map undo"				revert last command

# Create backup for undo
rm -rf "$HOME/Documents/bashmapper/undo/"
cp -r "$HOME/Documents/bashmapper/home/" "$HOME/Documents/bashmapper/undo/"

# Ensure map root directory exists
if [ ! -d "$HOME/Documents/bashmapper/home/" ]; then
    mkdir "$HOME/Documents/bashmapper/home/"
fi

# Undo functionality
if [[ "$1" == "undo" ]]; then
	rm -rf "$HOME/Documents/bashmapper/home/"
	cp -r "$HOME/Documents/bashmapper/undo/" "$HOME/Documents/bashmapper/home/"
	cd "$HOME/Documents/bashmapper/home/"
	
# Reset map view ("map root")
elif [[ "$1" == "home" || "$1" == "root" ]]; then
	cd "$HOME/Documents/bashmapper/home/"
	
# Navigate up ("map up")
elif [[ "$1" == "up" ]]; then
	cd ".."
	
# Targeted actions
elif [[ "${#1}" -eq 3 ]]; then

	# Fetch file name (only search current directory)
	filename=$(find . -maxdepth 1 -iname "${1}*")

	# Remove a signature and all of its contents
	if [[ "$2" == "rm" ]]; then
		echo "rm -rf $filename"
	
	# Navigate wormholes ("map xyz")
	elif [[ "$#" -eq 1 ]]; then
		cd "$filename"
		
	# Label signatures ("map xyz 123456")
	else
		id=$(echo "$filename" | cut -c1-5)
		tempname=$(echo "$id" "$2")
		if [[ "${#2}" == 6 ]]; then
			newname=$(grep -hr "$2" "$HOME/Documents/bashmapper/data.txt")
			mv "$PWD/$filename" "$PWD/$id $newname"
		else
			mv "$PWD/$filename" "$PWD/$tempname"
		fi
	fi

# Paste signatures in current directory ("map")
elif [[ "$#" -eq 0 ]]; then

	# Store clipboard & convert all whitespace to single spaces
	wl-paste | sed -e "s/[[:space:]]\+/ /g" | tr -s ' ' > "$HOME/Documents/bashmapper/clipboard.txt"

	# Iterate clipboard lines
	cat "$HOME/Documents/bashmapper/clipboard.txt" | while read -r line || [ -n "$line" ]; do

		# Store identifier (e.g., "ABC")
		head=$(echo "$line" | cut -c1-3)

		# Remove tail (everything after site name)
		tail=$(echo "$line" | cut -c 9-)
		nums='^[0-9]+$'
		for (( i=0; i<${#tail}; i++ )); do
		
			# Break out when a number is found
			if [[ "${tail:$i:1}" =~ $nums ]] ; then
				break
			fi
		done

		# Concatenate new string and remove irrelevant bits
		tailReal=$(echo "$tail" | cut -c1-"$i")
		newText=$(echo "${head} ${tailReal}" | sed -e 's/Cosmic Signature //' -e 's/Unstable Wormhole//' -e 's/Wormhole//')
		#  -e 's/Gas Site //' -e 's/Data Site //' -e 's/Relic Site //'

		# 'Overwriting' functionality
		checkExisting=$(find . -maxdepth 1 -name "${head}*")
		if [[ ${#checkExisting} -lt ${#newText} ]]; then

			# We literally just have to compare string lengths
			if [[ ${#checkExisting} -gt 0 ]]; then
				mv "$PWD/$checkExisting" "$PWD/$newText"
			else
				mkdir "$PWD/$newText"
			fi
		fi

		# 'Cleanup' functionality (lazy delete in Pathfinder/Wanderer)
		touch "$HOME/Documents/bashmapper/del.txt"
		for file in */; do
		
			# Get head ("ABC-123")
			head=$(echo "$file" | cut -c1-3)

			# Delete signature if it doesnt exist on clipboard
			if ! grep -q "$head" "$HOME/Documents/bashmapper/clipboard.txt"; then
				rm -rf "$file"
				echo "Delete bookmark: $head" >> "$HOME/Documents/bashmapper/del.txt"
			fi
		done
	done
fi

# Print updated map
clear
echo "=================================================="
echo "CURRENT SIGNATURE: ${PWD##*/}"
echo "=================================================="
tree -LC 1 | tail -n+2 - | head -n -3
	#-D for timestamps

# Indicate signatures for removal
if [[ -s "$HOME/Documents/bashmapper/del.txt" ]]; then
	echo "OBSOLETE SIGNATURES:"
	while read line; do
		echo $line
	done < "$HOME/Documents/bashmapper/del.txt"
	rm "$HOME/Documents/bashmapper/del.txt"
fi
