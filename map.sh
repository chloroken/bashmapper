#!/bin/bash

# COMMAND					BEHAVIOR
# "map" 					paste signatures
# "map up" 					navigate up
# "map root" 				navigate to root of map
# "map <sig>" 				navigate down
# "map <sig> rm" 			remove a signature
# "map <sig> <nickname>"	name a signature
# "map <sig> <jcode>"		fetch statics/weather

if [ ! -d "$HOME/Documents/bashmapper/home/" ]; then
    mkdir "$HOME/Documents/bashmapper/home/"
fi

# Reset map view ("map root")
if [[ "$1" == "root" ]]; then
	cd "$HOME/Documents/bashmapper/home/"
	echo "=================================================="
	echo "FULL MAP"
	echo "=================================================="
	tree -C
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
		newText=$(echo "${head} ${tailReal}" | sed -e 's/Cosmic Signature //' -e 's/Gas Site //' -e 's/Data Site //' -e 's/Relic Site //' -e 's/Unstable Wormhole//' -e 's/Wormhole//')

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
		for file in */; do
		
			# Get head ("ABC-123")
			head=$(echo "$file" | cut -c1-3)

			# Delete signature if it doesnt exist on clipboard
			if ! grep -q "$head" "$HOME/Documents/bashmapper/clipboard.txt"; then
				rm -rf "$file"
				echo "Removing signature: $head"
			fi
		done
	done
fi

if [[ "$1" != "root" ]]; then
	# Print map
	echo "=================================================="
	echo "CURRENT SYSTEM: ${PWD##*/}"
	echo "=================================================="
	tree -LC 1 #-D for timestamps
fi
