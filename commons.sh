#!/bin/bash

get_bug_statistics() {
	local file_path=$1
	
	if [ ! -f "$file_path" ]; then
		echo "File not found: $file_path"
		return 1
	fi
	
	awk 'BEGIN {fixed=0;} {if ($3 == 0) fixed++; if ($2 == 1) overall++;} END {print fixed" / "overall " (" fixed/overall")";}' "$file_path"
}
