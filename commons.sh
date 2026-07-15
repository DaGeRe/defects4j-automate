#!/bin/bash

get_bug_statistics() {
	local file_path=$1
	
	if [ ! -f "$file_path" ]; then
		echo "File not found: $file_path"
		return 1
	fi
	
	awk 'BEGIN {fixed=0;} {if ($3 == 0) fixed++; if ($2 == 1) overall++;} END {print fixed" / "overall " (" fixed/overall")";}' "$file_path"
}

getTestFromLogfile() {
	logfile=$1
	raw_line=$(grep -E "Failed tests|Tests in error" -A 1 $logfile | sed 's/^[[:space:]]*//')
	echo "line: $raw_line" >&2
	test=$(echo "$raw_line" | grep -oE '\([^)]+\)' | grep "Test" | grep -v "expected type: " | head -n 1 | tr -d '()' | xargs)
	if [ -z $test ]; then
		test=$(cat $logfile | grep "Failed tests\|Tests in error" -A 1 | tail -n 1 | grep -v "(" | grep -v "#" | awk -F'.' '{print $1}' | xargs)
	fi
	if [ -z $test ]; then
		test=$(cat $logfile | grep "Failed tests\|Tests in error" -A 1 | tail -n 1 | grep "(" | grep ")" | awk -F'[()]' '{print $2}' | grep "Test" | xargs)
	fi
	
	if [ -z "$test" ]; then
		maven_line=$(grep -E "^\[ERROR\] Failures:" -A 1 $logfile | tail -n 1)
		echo "maven_line=$maven_line" >&2
		if [ ! -z "$maven_line" ]; then
   			test=$(echo "$maven_line" | sed 's/\[ERROR\]//g' | awk -F'.' '{print $1}' | xargs)
		fi
	fi
	if [[ -z "$test" && "$raw_line" == *"#"* ]]; then
		test=$(echo "$raw_line" | tail -n 1 | awk -F':' '{print $1}' | awk -F'#' '{print $1}' | tr -d " ")
	fi
	if [ -z "$test" ]; then
		test=$(echo "$raw_line" | tail -n 1 | awk -F':' '{print $1}' | awk -F'.' '{print $1}' | tr -d " ")
	fi
	
	echo $test
}

fixPomXML() {
	PROJECTFOLDER=$1
	echo "Fixing pom.xml"
	sed -i 's/<maven.compile.source>1.6<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.6<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $PROJECTFOLDER/pom.xml
	sed -i 's/<maven.compile.source>1.5<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.5<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $PROJECTFOLDER/pom.xml
	sed -i 's/<maven.compiler.source>1.5<\/maven.compiler.source>/<maven.compiler.source>1.8<\/maven.compiler.source>/g; s/<maven.compiler.target>1.5<\/maven.compiler.target>/<maven.compiler.target>1.8<\/maven.compiler.target>/g' $PROJECTFOLDER/pom.xml
	sed -i 's/<maven.compile.source>1.4<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.4<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $PROJECTFOLDER/pom.xml
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
}
