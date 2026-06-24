#for i in 0 1 2 3 5 6 7; do
for i in 0; do
	#for project in Lang JacksonDatabind Jsoup; do
	for project in JacksonDatabind; do
		echo -n "$project uninformed "
		awk 'BEGIN {fixed=0;} {if ($3 == 0) fixed++; if ($2 == 1) overall++;} END {print fixed" / "overall " (" fixed/overall")";}' iteration-$i/defects4j-automate/bugs_$project"_uninformed.txt"
		echo -n "$project semi-informed "
		awk 'BEGIN {fixed=0;} {if ($3 == 0) fixed++; if ($2 == 1) overall++;} END {print fixed" / "overall " (" fixed/overall")";}' iteration-$i/defects4j-automate/bugs_$project"_semi-informed.txt"
		echo -n "$project informed "
		awk 'BEGIN {fixed=0;} {if ($3 == 0) fixed++; if ($2 == 1) overall++;} END {print fixed" / "overall " (" fixed/overall")";}' iteration-$i/defects4j-automate/bugs_$project"_informed.txt"
	done
done
