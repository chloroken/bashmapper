# bashmapper

Bash mapper is a CLI mapping tool for EVE Online. It is currently under development.

### Requirements:
- Linux & Wayland
- The `wl-clipboard` package (https://github.com/bugaevc/wl-clipboard)
- An alias like `alias map='~/Documents/bashmapper/map.sh`

### Commands:
```
[COMMAND]					[BEHAVIOR]
map add					    additively paste sigs
map lazy					'lazy-delete' paste
map undo					revert last command

[NAVIGATION]				[BEHAVIOR]
map up 					    navigate up
map top 					navigate to home system
map nav <sig> <sig>.. 	    navigate down one or more wormholes
map full 					show full map

[SIGNATURES]				[BEHAVIOR]
map <sig> <label>			rename a sig (accepts multiple words)
map <sig> flag			    add "!" after first word (e.g., "ABC 5x!")
map <sig> <jcode>			fetch class/statics/weather
map del <sig> <sig>..		remove one or more signatures```
