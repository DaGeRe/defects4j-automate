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
	project_folder=$1
	bug_id=$2
	echo "Fixing pom.xml"
	sed -i 's/<maven.compile.source>1.6<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.6<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $project_folder/pom.xml
	sed -i 's/<maven.compile.source>1.5<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.5<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $project_folder/pom.xml
	sed -i 's/<maven.compiler.source>1.5<\/maven.compiler.source>/<maven.compiler.source>1.8<\/maven.compiler.source>/g; s/<maven.compiler.target>1.5<\/maven.compiler.target>/<maven.compiler.target>1.8<\/maven.compiler.target>/g' $project_folder/pom.xml
	sed -i 's/<maven.compile.source>1.4<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.4<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $project_folder/pom.xml
	sed -i 's/<maven.compile.source>1.3<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.3<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $project_folder/pom.xml
	sed -i 's/<maven.compile.source>1.2<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.2<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $PROJECTproject_folderFOLDER/pom.xml
	sed -i 's/<maven.compile.source>1.1<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.1<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' $project_folder/pom.xml
	sed -i '/<artifactId>junit<\/artifactId>/{n;s/<version>3.8.1<\/version>/<version>4.13.2<\/version>/}' $project_folder/pom.xml
	sed -i 's|<source>1.5</source>|<source>1.8</source>|g' $project_folder/pom.xml
	sed -i 's|<target>1.5</target>|<target>1.8</target>|g' $project_folder/pom.xml
	
	# Fix for JacksonDatabind
	if [ -f $project_folder/src/main/java/com/fasterxml/jackson/databind/cfg/PackageVersion.java ]; then
		rm -f $project_folder/src/main/java/com/fasterxml/jackson/databind/cfg/PackageVersion.java
		COMPILER_PLUGIN="<plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-compiler-plugin</artifactId><version>2.5.1</version><configuration><source>1.8</source><target>1.8</target><showWarnings>false</showWarnings><failOnWarning>false</failOnWarning><compilerArgument>-Xlint:-deprecation</compilerArgument></configuration></plugin>"

		sed -i.bak "/<plugins>/a $COMPILER_PLUGIN" $project_folder/pom.xml
	fi
	
	SEVEN_T_TEST_FILE="$project_folder/src/test/java/org/apache/commons/compress/archivers/sevenz/SevenZNativeHeapTest.java"
	if [ "$bug_id" == "41" ] && [ -f "$SEVEN_T_TEST_FILE" ]; then
		ANNOTATION="@org.powermock.core.classloader.annotations.PowerMockIgnore({\"jdk.internal.reflect.*\", \"java.lang.*\", \"java.util.*\"})"
		
		sed -i "/public class SevenZNativeHeapTest/i $ANNOTATION" "$SEVEN_T_TEST_FILE"
	fi
	
	if [[ "$project_folder" == */Compress* ]] && [ "$bug_id" -gt 8 ]; then
		plugin_block='      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <configuration>
          <argLine>-javaagent:/home/reichelt/nvme/workspaces/kiekerworkspace/defects4j-automate/kieker-2.0.2-bytebuddy.jar --add-opens=java.base/java.lang=ALL-UNNAMED</argLine>
        </configuration>
      </plugin>'
		awk -v block="$plugin_block" '/<build>/ { print; in_build = 1; next }
    in_build && /<plugins>/ { print; print block; in_build = 0; next }
    { print }
			' $project_folder/pom.xml > $project_folder/pom.xml.tmp && mv $project_folder/pom.xml.tmp $project_folder/pom.xml
	fi
	cat $project_folder/pom.xml | grep "maven.compile"
}
