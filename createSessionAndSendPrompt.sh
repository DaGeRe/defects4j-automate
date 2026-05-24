
function fixBug {
	BUG=$1
	test=$2
	
	SESSION=$(curl -X POST localhost:4096/session?directory=/tmp/lang_3_buggy)

	echo $SESSION | jq

	SESSION_ID=$(echo $SESSION | jq ".id" | tr -d "\"")

	echo "SESSION_ID: $SESSION_ID"

#curl -X POST http://127.0.0.1:4096/session/$SESSION_ID/prompt_async \
#	-H "Content-Type: application/json" \
#	-d '{"agent":"build",
#	    "model":{"modelID":"gemma4:31b","providerID":"ollama"},
#	    "messageID":"msg_e55b6d7db001kRZ0w06AuCPzQF",
#	    "parts":[{"id":"prt_e55b6d7dc001LOiNhkSKyAlLXn",
#	    "type":"text",
#	    "text":"Fix mvn clean test"}]
#	  }'
	message="Fix mvn clean test -Dtest=$test"
	echo "Message: $message"
	curl -X POST "http://localhost:4096/session/$SESSION_ID/message" \
		-H "Content-Type: application/json" \
		--data @- <<EOF
{
  "model": {
    "providerID": "ollama",
    "modelID": "gemma4:31b"
  },
  "parts": [
    {
      "type": "text",
      "text": "$message"
    }
  ]
}
EOF
}

# Defects4j requires english locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

BUGS=$(cat ../defects4j/framework/projects/Lang/active-bugs.csv | awk '{print $1}')

echo $BUGS
mv bugs.txt bugs_old.txt

mkdir -p runs

for BUG in $BUGS
do
	if [ ! -d /tmp/lang_"$BUG"_buggy ]
	then
		defects4j checkout -p Lang -v "$BUG"b -w /tmp/lang_"$BUG"_buggy
		echo "target" >> /tmp/lang_"$BUG"_buggy/.gitignore
	fi

	sed -i 's/<maven.compile.source>1.6<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.6<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' /tmp/lang_"$BUG"_buggy/pom.xml

	(cd /tmp/lang_"$BUG"_buggy/ && mvn clean test) &> runs/before_"$BUG".txt
	
	RETURN_CODE_BEFORE=$?
	
	test=$(cat runs/before_"$BUG".txt | grep "Failed tests\|Tests in error" -A 1 | tail -n 1 | awk -F'.' '{print $1}' | xargs)
	
	echo "Fixing $test in $BUG"
	fixBug $BUG $test
	
	echo
	echo
	(cd /tmp/lang_"$BUG"_buggy/ && mvn clean test) &> runs/after_"$BUG".txt
	RETURN_CODE_AFTER=$?
	echo "$BUG $RETURN_CODE_BEFORE $RETURN_CODE_AFTER $test" >> bugs.txt
done
