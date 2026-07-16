#!/bin/bash

editSurefire() {
	PROJECT=$1
	PROJECTFOLDER=$2
	BUG=$3
		
	AGENT_PATH="-javaagent:"$(pwd)"/kieker-2.0.2-bytebuddy.jar"
	if [ "$PROJECT" == "Lang" ] && [ "$BUG" == "47" ]; then
		NEW_PLUGIN="<plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-surefire-plugin</artifactId><configuration><argLine>$AGENT_PATH</argLine></configuration></plugin>"
		sed -i "/<plugins>/a $NEW_PLUGIN" "$PROJECTFOLDER/pom.xml"
	else
		if ! xmlstarlet sel -t -v "//*[local-name()='plugin']/*[local-name()='artifactId']='maven-surefire-plugin'" "$PROJECTFOLDER/pom.xml" | grep -q "true"; then
			NEW_PLUGIN="<plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-surefire-plugin</artifactId><configuration><argLine>$AGENT_PATH --add-opens=java.base/java.lang=ALL-UNNAMED</argLine></configuration></plugin>"
			sed -i "/<plugins>/a $NEW_PLUGIN" "$PROJECTFOLDER/pom.xml"
		else
			xmlstarlet ed -L \
				-s "//*[local-name()='plugin'][*[local-name()='artifactId']='maven-surefire-plugin'][not(*[local-name()='configuration'])]" \
				-t elem -n "configuration" -v ""   \
				-s "//*[local-name()='plugin'][*[local-name()='artifactId']='maven-surefire-plugin']/*[local-name()='configuration'][not(*[local-name()='argLine'])]" \
				-t elem -n "argLine" \
				-v "$AGENT_PATH --add-opens=java.base/java.lang=ALL-UNNAMED" \
				$PROJECTFOLDER/pom.xml
		fi
	fi
}

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
	
	if [ -f $PROJECTFOLDER/pom.xml ]; then
		fixPomXML $PROJECTFOLDER $BUG
		
		(cd $PROJECTFOLDER/ && mvn clean test) &> $runfolder/before_"$BUG".txt
		
		RETURN_CODE_BEFORE=$?
		
		test=$(getTestFromLogfile $runfolder/before_"$BUG".txt)
		
		echo "Test: $test"
		if [ -z "$test" ]
		then
			echo "No failing tests; skipping bug $BUG"
			echo "$BUG skipped_no_failing_test" >> bugs"_"$PROJECT.txt
		else
			echo "Getting tree for $test in $BUG"
			sed -i '/<dependencies>/a <dependency><groupId>org.slf4j</groupId><artifactId>slf4j-simple</artifactId><version>2.0.18</version><scope>test</scope></dependency>' $PROJECTFOLDER/pom.xml
			
			editSurefire $PROJECT $PROJECTFOLDER $BUG
			echo "KIEKER_SIGNATURES_INCLUDE: $KIEKER_SIGNATURES_INCLUDE"
			
			(cd $PROJECTFOLDER && git checkout D4J_"$PROJECT"_"$BUG"_FIXED_VERSION)
			(cd $PROJECTFOLDER/ && mvn clean test -Dtest=$test) &> $runfolder/gettrace_"$BUG".txt
			
			tracelength=$(cat /tmp/kieker*/kieker*.dat | wc -l)
			uniquemethods=$(cat /tmp/kieker*/kieker*.dat | awk -F';' '{print $3}' | sort | uniq | wc -l)
			maxdepth=$(cat /tmp/kieker*/kieker*.dat | awk -F';' '{print $10}' | sort -n | tail -n 1)
			topLevelCalls=$(cat /tmp/kieker*/kieker*.dat | grep ";0;0$" | wc -l)
			echo "$PROJECT $BUG $test TraceLength=$tracelength uniquemethods=$uniquemethods maxdepth=$maxdepth topLevelCalls=$topLevelCalls" >> tracelength.txt
			
			# rm -rf $PROJECTFOLDER
		fi
	fi
done
