function getSum {
	  awk -vOFMT=%.10g '{sum += $1; square += $1^2} END {print sqrt(square / NR - (sum/NR)^2)" "sum/NR" "NR}'
}

for project in Lang JacksonDatabind Jsoup; do
     echo -n "$project & "
	for mode in "uninformed" "semi-informed" "informed"; do
		./analyze.sh $project | grep " $mode" | awk '{print $3 / $5}' | getSum | awk '{printf "%.2f\\%", $2*100}'
		echo -n " & "
	done
	echo " \\\\"
done
