#!/usr/bin/env bats

source ../commons.sh

@test "Check whether example JacksonDatabind output works" {
	testcase=$(getTestFromLogfile before_34.txt)
	
	echo "Expected: NewSchemaTest Was: $testcase"
	[ "$testcase" = "NewSchemaTest" ]
}
