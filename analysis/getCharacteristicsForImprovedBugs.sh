FILE1=$1
FILE2=$2

THRESHOLD=0.5

awk '
NR==FNR { 
    val1[$1] = $2; 
    next 
} 
FNR>1 && ($1 in val1) && (val1[$1] - $2 > '$THRESHOLD') { 
    diff = val1[$1] - $2;
    testname = $8;
    steps = $3;
    printf "BugID %-5s: %.4f / %.4f (Diff: %.4f) %s Steps: %s\n", $1, val1[$1], $2, diff, testname, steps;
}' "$FILE1" "$FILE2"

awk '
NR==FNR { 
    for (i=2; i<=NF; i++) val1[$1, i] = $i; 
    next 
} 
FNR==1 { 
    for (i=1; i<=NF; i++) head[i] = $i; 
    next 
} 
($1, 2) in val1 && (val1[$1, 2] - $2 > '$THRESHOLD') { 
    count++; 
    for (i=2; i<=NF; i++) {
        sum1[i] += val1[$1, i];  # Summe für Datei 1 (uninformed)
        sum2[i] += $i;           # Summe für Datei 2 (semi-informed)
    }
} 
END { 
    if (count > 0) { 
        print "Durchschnitte fuer gematchte Zeilen (Datei 1 / Datei 2):"; 
        for (i=2; i<=NF; i++) {
            avg1 = sum1[i] / count;
            avg2 = sum2[i] / count;
            printf "%-15s: %.4f / %.4f\n", head[i], avg1, avg2; 
        }
    } else { 
        print "Keine Zeilen gefunden."; 
    } 
}' $1 $2
