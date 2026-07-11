#!/bin/bash

export PROJECT="${1:-lang}"

if [[ ! "$MODE" =~ ^(uninformed|semi-informed|informed)$ ]]; then
	export MODE="uninformed"
else
	export $MODE
fi

echo "Current Mode: $MODE"

function fixBug {
	BUG=$1
	test=$2
	location=$3
	methods=$4
	
	FOLDER="/tmp/"$PROJECT"_"$BUG"_buggy"
	
	if [ "$MODE" = "uninformed" ]; then
		(cd $FOLDER && opencode run --format json "Fix mvn clean test -Dtest=$test")
	elif [ "$MODE" = "semi-informed" ]; then
		(cd $FOLDER && opencode run --format json "Fix mvn clean test -Dtest=$test Do not search the repository. The bug is located in the file $location.")
	elif [ "$MODE" = "informed" ]; then
		(cd $FOLDER && opencode run --format json "Fix mvn clean test -Dtest=$test Do not search the repository. The bug is located in the file $location. It is caused by the methods $methods")
	fi
}
export -f fixBug

# Defects4j requires english locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [ ! -f ../defects4j/framework/projects/$PROJECT/active-bugs.csv ]; then
	echo "File ../defects4j/framework/projects/$PROJECT/active-bugs.csv not found; project needs to be existing."
	exit 1
fi

BUGS=$(cat ../defects4j/framework/projects/$PROJECT/active-bugs.csv | awk -F"," '{print $1}' | grep -v "bug.id")

echo $BUGS
mv bugs_"$PROJECT"_"$MODE".txt bugs_"$PROJECT"_"$MODE"_old.txt

runfolder="runs_"$PROJECT"_"$MODE
mkdir -p $runfolder

for BUG in $BUGS
do
	PROJECTFOLDER=/tmp/"$PROJECT"_"$BUG"_buggy
	if [ ! -d $PROJECTFOLDER ]
	then
		defects4j checkout -p $PROJECT -v "$BUG"b -w $PROJECTFOLDER
		echo "target" >> $PROJECTFOLDER/.gitignore
	fi

	if [ -f $PROJECTFOLDER/pom.xml ]
	then
		echo "Fixing pom.xml"
		sed -i 's/<maven.compile.source>1.6<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.6<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $PROJECTFOLDER/pom.xml
		sed -i 's/<maven.compile.source>1.5<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.5<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $PROJECTFOLDER/pom.xml
		sed -i 's/<maven.compile.source>1.3<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.3<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $PROJECTFOLDER/pom.xml
		sed -i 's/<maven.compile.source>1.2<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.2<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $PROJECTFOLDER/pom.xml
		sed -i 's/<maven.compile.source>1.1<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.1<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $PROJECTFOLDER/pom.xml
		sed -i '/<artifactId>junit<\/artifactId>/{n;s/<version>3.8.1<\/version>/<version>4.13.2<\/version>/}' $PROJECTFOLDER/pom.xml
		sed -i 's|<source>1.5</source>|<source>1.8</source>|g' $PROJECTFOLDER/pom.xml
		sed -i 's|<target>1.5</target>|<target>1.8</target>|g' $PROJECTFOLDER/pom.xml
		
		# Fix for JacksonDatabind
		if [ -f $PROJECTFOLDER/src/main/java/com/fasterxml/jackson/databind/cfg/PackageVersion.java ]; then
			rm -f $PROJECTFOLDER/src/main/java/com/fasterxml/jackson/databind/cfg/PackageVersion.java
			COMPILER_PLUGIN="<plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-compiler-plugin</artifactId><version>2.5.1</version><configuration><source>1.8</source><target>1.8</target><showWarnings>false</showWarnings><failOnWarning>false</failOnWarning><compilerArgument>-Xlint:-deprecation</compilerArgument></configuration></plugin>"

			sed -i.bak "/<plugins>/a $COMPILER_PLUGIN" $PROJECTFOLDER/pom.xml
		fi
		
		cat $PROJECTFOLDER/pom.xml | grep "maven.compile"

		(cd $PROJECTFOLDER/ && mvn clean test) &> $runfolder/before_"$BUG".txt
		
		RETURN_CODE_BEFORE=$?
		
		raw_line=$(grep -E "Failed tests|Tests in error" -A 1 $runfolder/before_"$BUG".txt)
		echo "line: $raw_line"
		test=$(echo "$raw_line" | grep -oE '\([^)]+\)' | head -n 1 | tr -d '()' | xargs)
		if [ -z $test ]; then
			test=$(cat $runfolder/before_"$BUG".txt | grep "Failed tests\|Tests in error" -A 1 | tail -n 1 | grep -v "(" | awk -F'.' '{print $1}' | xargs)
		fi
		if [ -z $test ]; then
			test=$(cat $runfolder/before_"$BUG".txt | grep "Failed tests\|Tests in error" -A 1 | tail -n 1 | grep "(" | awk -F'[()]' '{print $2}' | xargs)
		fi
		if [ -z "$test" ]; then
			maven_line=$(grep -E "^\[ERROR\] Failures:" -A 1 $runfolder/before_"$BUG".txt | tail -n 1)
			if [ ! -z "$maven_line" ]; then
        			test=$(echo "$maven_line" | sed 's/\[ERROR\]//g' | awk -F'.' '{print $1}' | xargs)
			fi
		fi
		
		echo "Test: $test"
		if [ -z "$test" ]
		then
			echo "No failing tests; skipping bug $BUG"
			echo "$BUG skipped_no_failing_test" >> bugs"_"$PROJECT"_"$MODE.txt
		else
			echo "Fixing $test in $BUG"
			location=$(cd $PROJECTFOLDER && git diff --name-only D4J_"$PROJECT"_"$BUG"_BUGGY_VERSION..D4J_"$PROJECT"_"$BUG"_FIXED_VERSION | grep .java)
			echo "Location hint: $location"
			
			if [ "$MODE" = "informed" ]; then
				./getDifferingMethods.sh $PROJECTFOLDER D4J_"$PROJECT"_"$BUG"_BUGGY_VERSION D4J_"$PROJECT"_"$BUG"_FIXED_VERSION
				methods=$(jq -r 'to_entries[] | "\(.key)#\(.value.changedMethods | keys[])"' $PROJECTFOLDER/out.json)
				echo "Fix methods: $methods"
			fi
			
			timeout --foreground 15m bash -c "fixBug '$BUG' '$test' '$location' '$methods'" &> $runfolder/fixing_"$BUG".txt
		
		
			(cd $PROJECTFOLDER/ && mvn clean test) &> $runfolder/after_"$BUG".txt
			RETURN_CODE_AFTER=$?
			echo "$BUG $RETURN_CODE_BEFORE $RETURN_CODE_AFTER $test" >> bugs"_"$PROJECT"_"$MODE.txt
			echo "Fix successful: $RETURN_CODE_AFTER"
		fi
	else
		echo "No pom.xml; skipping bug $BUG"
		echo "$BUG skipped_no_maven" >> bugs_"$PROJECT"_"$MODE".txt
	fi
	
	echo
	echo
	
	rm -rf $PROJECTFOLDER
done
