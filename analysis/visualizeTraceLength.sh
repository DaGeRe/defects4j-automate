#!/bin/bash

PROJECT=$1
MODE=$2
IDENTIFIER=$1"-"$MODE
OUTPUT="results-$IDENTIFIER.csv"

echo "BugID FixProbability Steps Tokens TraceLength UniqueMethods MaxDepth" > $OUTPUT

cat raw.txt | grep $IDENTIFIER | awk '
{
    sum[$2] += ($3 == 0 ? 0 : 1);
    count[$2]++;
    steps[$2] += $4+$5;
    tokens[$2] += $6;
} 
END {
    for (id in sum) {
        printf "%d %.4f %.4f %.4f\n", id, sum[id]/count[id], steps[id]/count[id], tokens[id]/count[id];
    }
}' > temp_probs.txt

cat tracelength.txt | grep "$PROJECT" > temp_length.txt

awk '
NR==FNR {
    prob[$1] = $2;
    steps[$1] += $3;
    tokens[$1] += $4;
    next;
}
{
    # Extrahiere Daten aus Datei 2 (Format: Lang [ID] TraceLength=... etc)
    bugid = $2;
    testname = $3;
    trace = gensub(/TraceLength=([0-9]+)/, "\\1", "g", $4);
    methods = gensub(/uniquemethods=([0-9]+)/, "\\1", "g", $5);
    depth = gensub(/maxdepth=([0-9]+)/, "\\1", "g", $6);
    
    if (bugid in prob) {
        printf "%s %.4f %.4f %.4f %s %s %s %s\n", bugid, prob[bugid], steps[bugid], tokens[bugid], trace, methods, depth, testname;
    }
}' temp_probs.txt temp_length.txt | grep -v "maxdepth=" >> $OUTPUT

rm temp_probs.txt temp_length.txt
