#!/bin/bash

# [COMMAND]					[BEHAVIOR]
# map paste					paste signatures
# map lazy					'lazy-delete' paste
# map undo					revert last command
# map <sig> rm 				remove a signature
#
# [NAVIGATION]				[BEHAVIOR]
# map up 					navigate up
# map home 					navigate to root (& show full tree)
# map <sig> 				navigate down a wormhole
#
# [LABELING]				[BEHAVIOR]
# map <sig> "<nickname>"	rename a sig (quotes for multiple words)
# map <sig> flag			add "!" after first word (e.g., "ABC 5x!")
# map <sig> <jcode>			fetch class/statics/weather

# Initialize magic strings
dir="$HOME/Documents/bashmapper"
divider="=================================================="

# Ensure map root directory exists
if [ ! -d "$dir/home/" ]; then
    mkdir "$dir/home/"
fi

# Create backup for undo
rm -rf "$dir/undo/"
cp -r "$dir/home/" "$dir/undo/"

# Undo functionality
if [[ "$1" == "undo" ]]; then
	rm -rf "$dir/home/"
	cp -r "$dir/undo/" "$dir/home/"
	cd "$dir/home/"
	
# Reset map view ("map home")
elif [[ "$1" == "home" ]]; then
	cd "$dir/home/"
	
# Navigate up ("map up")
elif [[ "$1" == "up" ]]; then
	cd ".."
	
# Targeted actions
elif [[ "${#1}" -eq 3 ]]; then

	# Fetch file name (only search current directory)
	filename=$(find . -maxdepth 1 -iname "${1}*")

	# Remove a signature and all of its contents
	if [[ "$2" == "rm" ]]; then
		rm -rf "$filename"
	
	# Navigate wormholes ("map xyz")
	elif [[ "$#" -eq 1 ]]; then
		cd "$filename"

	# Flag (!) signatures ("map xyz flag")
	elif [[ "$2" == "flag" ]]; then

		# Iterate through filename string
		preString="$filename"
		spaces=0
		for (( i=0; i<${#preString}; i++ )); do
		
			# Break out when second space is found
			if [[ "${preString:$i:1}" == " " ]]; then
				if [[ $spaces -ge 1 ]]; then
					break
				fi
				((spaces++))
			fi
		done

		# Update string with a flag (!)
		postString="${preString:0:$i}!${preString:$i}"
		mv "$filename" "$postString"
	
	# Label signatures ("map xyz 123456")
	else
		id=$(echo "$filename" | cut -c1-5)
		tempname=$(echo "$id" "$2")

		# Check if second parameter is a 6-char int like "111105"
		re='^[0-9]+$'
		if [[ "${#2}" -eq 6 && "${#2}" =~ $re ]]; then

			# Append class, static, and weather strings
			newname=$(grep -hr "$2" "$dir/data.txt")
			mv "$PWD/$filename" "$PWD/$filename $newname"
		else

			# Rename system
			mv "$PWD/$filename" "$PWD/$tempname"
		fi
	fi

# Paste signatures in current directory ("map")
elif [[ "$1" == "paste" || "$1" == "lazy" ]]; then #[[ "$#" -eq 0 ]]; then

	# Store clipboard & convert all whitespace to single spaces
	wl-paste | sed -e "s/[[:space:]]\+/ /g" | tr -s ' ' > "$dir/clipboard.txt"

	# Iterate clipboard lines
	cat "$dir/clipboard.txt" | while read -r line || [ -n "$line" ]; do

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
		newText=$(echo "${head} ${tailReal}" | sed -e 's/Cosmic Signature //' -e 's/Unstable Wormhole//' -e 's/Wormhole//' -e 's/Gas Site //' -e 's/Data Site //' -e 's/Relic Site //')

		# Signature 'overwriting' functionality
		checkExisting=$(find . -maxdepth 1 -name "${head}*")
		if [[ ${#checkExisting} -lt ${#newText} ]]; then

			# We literally just have to compare string lengths
			if [[ ${#checkExisting} -gt 0 ]]; then

				# And keep the longer one
				mv "$PWD/$checkExisting" "$PWD/$newText"
			else

				# Or overwrite it
				mkdir "$PWD/$newText"
			fi
		fi

		# 'Cleanup' functionality ('lazy delete' in Pathfinder/Wanderer)
		if [[ "$1" == "lazy" ]]; then

			# Create a temporary file with sigs we want to delete
			touch "$dir/del.txt"
			for file in */; do
			
				# Get signature label identifier ("ABC")
				head=$(echo "$file" | cut -c1-3)

				# Delete signature if it doesnt exist on clipboard
				if ! grep -q "$head" "$dir/clipboard.txt"; then
					rm -rf "$file"

					# Store deleted sig for later reference
					echo "$head" >> "$dir/del.txt"
				fi 
			done
		fi
	done

	# Clean up
	rm "$dir/clipboard.txt"
fi

# Print updated map
clear
echo $divider
echo "CURRENT LOCATION: ${PWD##*/}"
echo $divider
if [[ "${PWD##*/}" == "home" ]]; then
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
	done < "$dir/del.txt"
	echo $divider

	#Clean up
	rm "$dir/del.txt"
fi
