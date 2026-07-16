#!/usr/bin/env bats

source ../commons.sh

@test "Check whether pom.xml fix works for Collection bug id 20" {
	if [ -d Collection_20_buggy ]; then
		rm -r Collection_20_buggy
	fi
	mkdir Collection_20_buggy
	cp Collection_20_pom.xml Collection_20_buggy/pom.xml
	editSurefire Collections Collection_20_buggy 20
	
	argLine=$(cat Collection_20_buggy/pom.xml | grep "argLine")
	argLineContent=$(echo "$argLine" | awk -F'<argLine>|</argLine>' '{print $2}')
	
	echo "Expected: -javaagent:$(pwd)/kieker-2.0.2-bytebuddy.jar --add-opens=java.base/java.lang=ALL-UNNAMED"
	echo "Was: $argLineContent"
	[ "$argLineContent" = "-javaagent:$(pwd)/kieker-2.0.2-bytebuddy.jar --add-opens=java.base/java.lang=ALL-UNNAMED" ]
}
