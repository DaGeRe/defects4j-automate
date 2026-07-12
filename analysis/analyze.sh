
project=$1

for i in 0 1 2 3 4 5 6 7; do
     echo $i
	echo -n "$project uninformed "
	awk 'BEGIN {fixed=0;} {if ($3 == 0) fixed++; if ($2 == 1) overall++;} END {print fixed" / "overall " (" fixed/overall")";}' iteration-$i/bugs_$project"_uninformed.txt"
	echo -n "$project semi-informed "
	awk 'BEGIN {fixed=0;} {if ($3 == 0) fixed++; if ($2 == 1) overall++;} END {print fixed" / "overall " (" fixed/overall")";}' iteration-$i/bugs_$project"_semi-informed.txt"
	echo -n "$project informed "
	awk 'BEGIN {fixed=0;} {if ($3 == 0) fixed++; if ($2 == 1) overall++;} END {print fixed" / "overall " (" fixed/overall")";}' iteration-$i/bugs_$project"_informed.txt"
done
