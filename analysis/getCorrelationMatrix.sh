for project in Cli Compress JacksonCore JacksonDatabind Jsoup Lang Time; do 
	for mode in uninformed semi-informed informed; do 
		visualizeTraceLength.sh $project $mode
	done
done

for mode in uninformed semi-informed informed; do 
	echo "BugID FixProbability Steps Tokens TraceLength UniqueMethods MaxDepth DiffFileCount DiffMethodCount Test" > merged_$mode.csv
	echo $mode; cat results-*-"$mode".csv | grep -v "BugID" &>> merged_$mode.csv
	Rscript -e "d <- read.table('"merged_$mode.csv"', header=TRUE, row.names=NULL); options(width=200); print(cor(d[, -ncol(d)]))"
done;
