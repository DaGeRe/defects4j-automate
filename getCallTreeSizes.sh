#!/bin/bash

export PROJECT="${1:-Lang}"

source commons.sh

if [ "$PROJECT" == "Lang" ]; then
	export KIEKER_SIGNATURES_INCLUDE="org.apache.commons.lang3.*;org.apache.commons.lang.*"
fi
if [ "$PROJECT" == "JacksonDatabind" ]; then
	export KIEKER_SIGNATURES_INCLUDE="com.fasterxml.jackson.databind.*"
fi
if [ "$PROJECT" == "Jsoup" ]; then
	export KIEKER_SIGNATURES_INCLUDE="org.jsoup.*"
fi

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [ ! -f ../defects4j/framework/projects/$PROJECT/active-bugs.csv ]; then
	echo "File ../defects4j/framework/projects/$PROJECT/active-bugs.csv not found; project needs to be existing."
	exit 1
fi

BUGS=$(cat ../defects4j/framework/projects/$PROJECT/active-bugs.csv | awk -F"," '{print $1}' | grep -v "bug.id")

echo $BUGS
mv bugs_"$PROJECT".txt bugs_"$PROJECT"_old.txt

runfolder="runs_"$PROJECT
mkdir -p $runfolder

if [ ! -f kieker-2.0.2-bytebuddy.jar ]; then
	echo "kieker-2.0.2-bytebuddy.jar missing"
	wget https://repo1.maven.org/maven2/net/kieker-monitoring/kieker/2.0.2/kieker-2.0.2-bytebuddy.jar
fi

for BUG in $BUGS
do
	rm -r /tmp/kieker* 
	PROJECTFOLDER=/tmp/"$PROJECT"_"$BUG"_buggy
	if [ ! -d $PROJECTFOLDER ]
	then
		# use "$BUG"f to get the fixed version
		defects4j checkout -p $PROJECT -v "$BUG"b -w $PROJECTFOLDER
		echo "target" >> $PROJECTFOLDER/.gitignore
	fi
	
	if [ -f $PROJECTFOLDER/pom.xml ]
	then
		fixPomXML $PROJECTFOLDER
		
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
			echo "$BUG skipped_no_failing_test" >> bugs"_"$PROJECT.txt
		else
			echo "Getting tree for $test in $BUG"
			sed -i '/<dependencies>/a <dependency><groupId>org.slf4j</groupId><artifactId>slf4j-simple</artifactId><version>2.0.18</version><scope>test</scope></dependency>' $PROJECTFOLDER/pom.xml
			xmlstarlet ed -L \
				-s "//*[local-name()='plugin'][*[local-name()='artifactId']='maven-surefire-plugin'][not(*[local-name()='configuration'])]" \
				-t elem -n "configuration" -v ""   \
				-s "//*[local-name()='plugin'][*[local-name()='artifactId']='maven-surefire-plugin']/*[local-name()='configuration'][not(*[local-name()='argLine'])]" \
				-t elem -n "argLine" \
				-v "-javaagent:"$(pwd)"/kieker-2.0.2-bytebuddy.jar" \
				$PROJECTFOLDER/pom.xml
			echo "KIEKER_SIGNATURES_INCLUDE: $KIEKER_SIGNATURES_INCLUDE"
			
			(cd $PROJECTFOLDER && git checkout D4J_"$PROJECT"_"$BUG"_FIXED_VERSION)
			(cd $PROJECTFOLDER/ && mvn clean test -Dtest=$test) &> $runfolder/gettrace_"$BUG".txt
			
			tracelength=$(cat /tmp/kieker*/kieker*.dat | wc -l)
			uniquemethods=$(cat /tmp/kieker*/kieker*.dat | awk -F';' '{print $3}' | sort | uniq | wc -l)
			maxdepth=$(cat /tmp/kieker*/kieker*.dat | awk -F';' '{print $10}' | sort -n | tail -n 1)
			echo "$PROJECT $BUG TraceLength=$tracelength uniquemethods=$uniquemethods maxdepth=$maxdepth" >> tracelength.txt
		fi
	fi
done
