#!/bin/bash

export PROJECT="${1:-Lang}"

source commons.sh

if [ -z "${JAVA_HOME}" ]; then
	echo "\$JAVA_HOME not set"
	exit 1
fi

if [ ! -d "${JAVA_HOME}" ]; then
	echo "\$JAVA_HOME points to invalid directory: ${JAVA_HOME}"
	exit 1
fi

if [ "$PROJECT" == "Lang" ]; then
	export KIEKER_SIGNATURES_INCLUDE="org.apache.commons.lang3.*;org.apache.commons.lang.*"
fi
if [ "$PROJECT" == "JacksonCore" ]; then
	export KIEKER_SIGNATURES_INCLUDE="com.fasterxml.jackson.core.*"
fi
if [ "$PROJECT" == "JacksonDatabind" ]; then
	export KIEKER_SIGNATURES_INCLUDE="com.fasterxml.jackson.databind.*"
fi
if [ "$PROJECT" == "Jsoup" ]; then
	export KIEKER_SIGNATURES_INCLUDE="org.jsoup.*"
fi
if [ "$PROJECT" == "Compress" ]; then
	export KIEKER_SIGNATURES_INCLUDE="org.apache.commons.compress.*"
fi
if [ "$PROJECT" == "Time" ]; then
	export KIEKER_SIGNATURES_INCLUDE="org.joda.time.*"
fi
if [ "$PROJECT" == "Cli" ]; then
	export KIEKER_SIGNATURES_INCLUDE="org.apache.commons.cli2.*"
fi
if [ "$PROJECT" == "Collections" ]; then
	export KIEKER_SIGNATURES_INCLUDE="org.apache.commons.collections.*;org.apache.commons.collections4.*"
fi
if [ "$PROJECT" == "Math" ]; then
	export KIEKER_SIGNATURES_INCLUDE="org.apache.commons.math3.*"
fi



export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [ ! -f ../defects4j/framework/projects/$PROJECT/active-bugs.csv ]; then
	echo "File ../defects4j/framework/projects/$PROJECT/active-bugs.csv not found; project needs to be existing."
	exit 1
fi

if [ "$PROJECT" == "Compress" ]; then
	BUGS=$(cat ../defects4j/framework/projects/$PROJECT/active-bugs.csv | awk -F"," '{print $1}' | grep -v "bug.id" | grep -v '^23$')
else
	BUGS=$(cat ../defects4j/framework/projects/$PROJECT/active-bugs.csv | awk -F"," '{print $1}' | grep -v "bug.id" )
fi

echo $BUGS
mv bugs_"$PROJECT".txt bugs_"$PROJECT"_old.txt

runfolder="runs_"$PROJECT
mkdir -p $runfolder

if [ ! -f kieker-2.0.2-bytebuddy.jar ]; then
	echo "kieker-2.0.2-bytebuddy.jar missing"
	wget https://repo1.maven.org/maven2/net/kieker-monitoring/kieker/2.0.2/kieker-2.0.2-bytebuddy.jar
fi

for bug_id in $BUGS
do
	rm -r /tmp/kieker* 
	PROJECTFOLDER=/tmp/"$PROJECT"_"$bug_id"_buggy
	if [ ! -d $PROJECTFOLDER ]
	then
		# use "$BUG"f to get the fixed version
		defects4j checkout -p $PROJECT -v "$bug_id"b -w $PROJECTFOLDER
		echo "target" >> $PROJECTFOLDER/.gitignore
	fi
	
	if [ -f $PROJECTFOLDER/pom.xml ]; then
		fixPomXML $PROJECTFOLDER $bug_id
		
		(cd $PROJECTFOLDER/ && mvn clean test) &> $runfolder/before_"$bug_id".txt
		
		RETURN_CODE_BEFORE=$?
		
		test=$(getTestFromLogfile $runfolder/before_"$bug_id".txt)
		
		echo "Test: $test"
		if [ -z "$test" ]
		then
			echo "No failing tests; skipping bug $bug_id"
			echo "$bug_id skipped_no_failing_test" >> bugs"_"$PROJECT.txt
		else
			echo "Getting tree for $test in $bug_id"
			sed -i '/<dependencies>/a <dependency><groupId>org.slf4j</groupId><artifactId>slf4j-simple</artifactId><version>2.0.18</version><scope>test</scope></dependency>' $PROJECTFOLDER/pom.xml
			
			editSurefire $PROJECT $PROJECTFOLDER $bug_id
			echo "KIEKER_SIGNATURES_INCLUDE: $KIEKER_SIGNATURES_INCLUDE"
			
			(cd $PROJECTFOLDER && git checkout D4J_"$PROJECT"_"$bug_id"_FIXED_VERSION)
			(cd $PROJECTFOLDER/ && mvn clean test -Dtest=$test) &> $runfolder/gettrace_"$bug_id".txt
			
			tracelength=$(cat /tmp/kieker*/kieker*.dat | wc -l)
			uniquemethods=$(cat /tmp/kieker*/kieker*.dat | awk -F';' '{print $3}' | sort | uniq | wc -l)
			maxdepth=$(cat /tmp/kieker*/kieker*.dat | awk -F';' '{print $10}' | sort -n | tail -n 1)
			topLevelCalls=$(cat /tmp/kieker*/kieker*.dat | grep ";0;0$" | wc -l)
			echo "$PROJECT $bug_id $test TraceLength=$tracelength uniquemethods=$uniquemethods maxdepth=$maxdepth topLevelCalls=$topLevelCalls" >> tracelength.txt
			
			# rm -rf $PROJECTFOLDER
		fi
	fi
done
