function getSum {
	  awk -vOFMT=%.10g '{sum += $1; square += $1^2} END {print sqrt(square / NR - (sum/NR)^2)" "sum/NR" "NR}'
}

for project in Lang Jackson; do
	echo $project
	for mode in "uninformed" "semi-informed" "informed"; do
		echo -n "$mode "
		./analyze.sh  | grep $project | grep " $mode" | awk '{print $3}' | getSum
	done
done
