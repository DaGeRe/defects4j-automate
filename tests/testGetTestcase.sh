#!/usr/bin/env bats

source ../commons.sh

@test "Check whether example Lang output works -- old JUnit" {
	testcase=$(getTestFromLogfile before_7.txt)
	
	echo "Expected: org.apache.commons.lang3.math.NumberUtilsTest Was: $testcase"
	[ "$testcase" = "org.apache.commons.lang3.math.NumberUtilsTest" ]
}

@test "Check whether example JacksonDatabind output works" {
	testcase=$(getTestFromLogfile before_34.txt)
	
	echo "Expected: NewSchemaTest Was: $testcase"
	[ "$testcase" = "NewSchemaTest" ]
}

@test "Check whether example JacksonDatabind output 2 works" {
	testcase=$(getTestFromLogfile before_88.txt)
	
	echo "Expected: GenericTypeId1735Test Was: $testcase"
	[ "$testcase" = "GenericTypeId1735Test" ]
}
