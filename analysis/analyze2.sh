function getSum {
	  awk -vOFMT=%.10g '{sum += $1; square += $1^2} END {print sqrt(square / NR - (sum/NR)^2)" "sum/NR" "NR}'
}

t_crit_values=(0 63.657 9.925 5.841 4.604 4.032 3.707 3.499 3.355 3.250 3.169 3.106 3.055 3.012 2.977 2.947)

GREEN='\033[0;32m'  # Für "significant change"
NC='\033[0m'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

for project in Cli Compress JacksonCore JacksonDatabind Jsoup Lang Time; do
	bug_count=$(cat iteration-0/bugs_"$project"_uninformed.txt  | grep -v "skipped_no_maven\|skipped_no_failing_test" | wc -l)
	echo "$project ($bug_count)"
	uninformed_values=$("$SCRIPT_DIR/analyze.sh" $project | grep " uninformed" | awk '{print $3 / $5}' | getSum)
	read -r deviation1 mean1 size1 <<< "$uninformed_values"

	echo -n "uninformed "
	echo $uninformed_values | awk '{printf "%.1f ± %.1f", $2 * 100, $1 * 100}'
	echo
	for mode in "semi-informed" "informed"; do
		echo -n "$mode "
		current=$("$SCRIPT_DIR/analyze.sh" $project | grep " $mode" | awk '{print $3 / $5}' | getSum)
		echo $current | awk '{printf "%.1f ± %.1f", $2 * 100, $1 * 100}'
		read -r deviation2 mean2 size2 <<< "$current"
		pooled_sd=$(echo "sqrt((($size1-1)*($deviation1^2) + ($size2-1)*($deviation2^2)) / ($size1+$size2-2))" | bc -l)
		tvalue=$(echo "scale=3; ($mean1 - $mean2) / ($pooled_sd * sqrt(2/$size1))" | bc -l)
		echo -n " t=$tvalue "
		
		abs_tvalue=$(echo "if ($tvalue < 0) -($tvalue) else $tvalue" | bc -l)
		df=$((size1 + size2 - 2))
		t_crit=${t_crit_values[$df]}
		
		if (( $(echo "$abs_tvalue > $t_crit" | bc -l) )); then
		    echo -e -n "$GREEN significant change $NC"
		fi
		echo 
	done
done
