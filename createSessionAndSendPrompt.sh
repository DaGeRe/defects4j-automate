
function fixBug {
	BUG=$1
	test=$2
	
	
	FOLDER="/tmp/lang_"$BUG"_buggy"
	
	(cd $FOLDER && opencode run "Execute pwd using bash and then fix mvn clean test -Dtest=$test")
	exit 1
	
	
	curl "localhost:4096/project/current?directory=$FOLDER"
	SESSION=$(curl -X POST "localhost:4096/session?directory=$FOLDER&roots=true")
	
	

	echo $SESSION | jq

	SESSION_ID=$(echo $SESSION | jq ".id" | tr -d "\"")
	
	echo "Patching..."
	curl -X PATCH \
		-H 'Content-Type: application/json' \
		"localhost:4096/session/$SESSION_ID?directory=$FOLDER" \
		--data '{"title": "Auto-Generated Fix-Session"}'

	echo "SESSION_ID: $SESSION_ID"
	
	sleep 1
	
	#echo "Init..." => Nicht sinnvoll, initialisiert Einzelnachrichten
	#curl -X POST "localhost:4096/session/$SESSION_ID/init?directory=$FOLDER" 
	
	echo "List messages..."
	curl "localhost:4096/session/$SESSION_ID/message?directory=$FOLDER&limit=200"
	
	
	
	message="Execute pwd using bash and then fix mvn clean test -Dtest=$test"
	echo "Message: $message"
	
	PAYLOAD=$(jq -n \
      --arg provider "ollama" \
      --arg model "gemma4:31b" \
      --arg msg "$message" \
      '{
        "agent": "build",
        "model": {
          "providerID": $provider,
          "modelID": $model
        },
        "parts": [
          {
            "type": "text",
            "text": $msg
          }
        ]
      }')

    # 4. Request an die korrekte Session-URL senden
    # URL-Struktur: /session/$SESSION_ID/prompt_async
    curl -i -X POST "http://localhost:4096/session/$SESSION_ID/prompt_async" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD"
        
    exit 1
	
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
export -f fixBug

# Defects4j requires english locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

BUGS=$(cat ../defects4j/framework/projects/Lang/active-bugs.csv | awk -F"," '{print $1}' | grep -v "bug.id")

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

	if [ -f /tmp/lang_"$BUG"_buggy/pom.xml ]
	then
		echo "Fixing pom.xml"
		sed -i 's/<maven.compile.source>1.6<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.6<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' /tmp/lang_"$BUG"_buggy/pom.xml
		sed -i 's/<maven.compile.source>1.5<\/maven.compile.source>/<maven.compile.source>1.8<\/maven.compile.source>/g; s/<maven.compile.target>1.5<\/maven.compile.target>/<maven.compile.target>1.8<\/maven.compile.target>/g' /tmp/lang_"$BUG"_buggy/pom.xml
		sync
		cat /tmp/lang_"$BUG"_buggy/pom.xml | grep "maven.compile"

		(cd /tmp/lang_"$BUG"_buggy/ && mvn clean test) &> runs/before_"$BUG".txt
		
		RETURN_CODE_BEFORE=$?
		
		testFailed=$(cat runs/before_"$BUG".txt | grep "Failed tests\|Tests in error" -A 1 | tail -n 1 | grep -v "(" | awk -F'.' '{print $1}' | xargs)
		testError=$(cat runs/before_"$BUG".txt | grep "Failed tests\|Tests in error" -A 1 | tail -n 1 | grep "(" | awk -F'[()]' '{print $2}' | xargs)
		
		if [ -n "$testFailed" ]; then
			test="$testFailed"
		else
			test="$testError"
		fi
		
		if [ -n "$test" ]
		then
			echo "No failing tests; skipping bug $BUG"
			echo "$BUG skipped_no_failing_test" >> bugs.txt
		else
			echo "Fixing $test in $BUG"
			timeout --foreground 15m bash -c "fixBug '$BUG' '$test'" &> runs/fixing_"$BUG".txt
		
		
			(cd /tmp/lang_"$BUG"_buggy/ && mvn clean test) &> runs/after_"$BUG".txt
			RETURN_CODE_AFTER=$?
			echo "$BUG $RETURN_CODE_BEFORE $RETURN_CODE_AFTER $test" >> bugs.txt
			echo "Fix successful: $RETURN_CODE_AFTER"
		fi
	else
		echo "No pom.xml; skipping bug $BUG"
		echo "$BUG skipped_no_maven" >> bugs.txt
	fi
	
	echo
	echo
done
