#!/bin/bash

source commons.sh

for project in Lang JacksonDatabind Jsoup
	do for mode in uninformed semi-informed informed
       		do echo $project-$mode
		export MODE="$mode"
	        ./promptBasic.sh $project &> "$project"_"$mode".txt
	        
	     get_bug_statistics bugs_$project"_"$mode".txt"
		
		echo "Cleaning old opencode instances"
		ps -aux | grep opencode | awk '{print $2}' | xargs kill -9
		echo
	done
done
