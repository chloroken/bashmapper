#!/bin/bash

# [COMMAND]					[BEHAVIOR]
# map paste					paste signatures
# map lazy					'lazy-delete' paste
# map undo					revert last command
#
# [NAVIGATION]				[BEHAVIOR]
# map up 					navigate up
# map top 					navigate to root (& show full tree)
# map <sig> 				navigate down a wormhole
#
# [SIGNATURES]				[BEHAVIOR]
# map <sig> "<nickname>"	rename a sig (quotes for multiple words)
# map <sig> flag			add "!" after first word (e.g., "ABC 5x!")
# map <sig> <jcode>			fetch class/statics/weather
# map <sig> rm 				remove a signature

# Initialize magic variables
dir="$HOME/Documents/bashmapper"
home="$dir/home/"
backup="$dir/undo/"
clipboard="$dir/clipboard.txt"
del="$dir/del.txt"
divider="=================================================="

# Ensure map root directory exists
if [ ! -d "$dir/home/" ]; then
    mkdir "$dir/home/"
fi

# Undo functionality
if [[ "$1" == "undo" ]]; then
	rm -rf "$home"

	# Restore backup
	cp -r "$backup" "$home"
	cd "$home"
else

	# Create backup
	rm -rf "$backup"
	cp -r "$home" "$backup"
fi

# Reset map view ("map top")
if [[ "$1" == "top" ]]; then
	cd "$home"

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
		spaces=0 # just use i
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

		# Check if second parameter is 6 characters
		if [[ "${#2}" -eq 6 ]]; then

			# If it's an integer (i.e., a jcode)
			re='^[0-9]+$'
			if [[ "${#2}" =~ $re ]]; then
			
				# Append class, static, and weather strings
				newname=$(grep -hr "$2" "$dir/data.txt")
				mv "$filename" "$filename $newname"
				cd "$filename $newname"
			else
			
				# Rename system
				mv "$filename" "$tempname"
			fi
		else
			# Rename system
			mv "$filename" "$tempname"
		fi
	fi

# Paste signatures in current directory ("map")
elif [[ "$1" == "paste" || "$1" == "lazy" ]]; then

	# Store clipboard & convert all whitespace to single spaces
	wl-paste | sed -e "s/[[:space:]]\+/ /g" | tr -s ' ' > "$clipboard"

	# Iterate clipboard lines
	cat "$clipboard" | while read -r line || [ -n "$line" ]; do

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
				mv "$checkExisting" "$newText"
			else

				# Or overwrite it
				mkdir "$newText"
			fi
		fi

		# 'Cleanup' functionality ('lazy delete' in Pathfinder/Wanderer)
		if [[ "$1" == "lazy" ]]; then

			# Create a temporary file with sigs we want to delete
			touch "$del"
			for file in */; do
			
				# Get signature label identifier ("ABC")
				head=$(echo "$file" | cut -c1-3)

				# Delete signature if it doesnt exist on clipboard
				if ! grep -q "$head" "$clipboard"; then
					rm -rf "$file"

					# Store deleted sig for later reference
					echo "$head" >> "$del"
				fi 
			done
		fi
	done

	# Clean up
	rm "$clipboard"
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
	done < "$del"
	echo $divider

	#Clean up
	rm "$del"
fi
