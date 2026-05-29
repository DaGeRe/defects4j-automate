
start=$(pwd)
if [ ! -d nodeDiffDetector ]; then
	git clone -b develop https://github.com/DaGeRe/nodeDiffDetector.git
	cd nodeDiffDetector
	mvn clean package -DskipTests -P buildStarter
	cd ..
fi

cd $1

files=$(git diff --name-only $2 $3 | grep .java)

for file in $files; do
	filename=$(basename $file)

	mkdir new
	git show "$2":$file > new/$filename

	mkdir old
	git show "$3":$file > old/$filename

	java -jar $start/nodeDiffDetector/nodeDiffDetector-starter/target/nodeDiffDetector-starter-0.0.3-SNAPSHOT.jar new/ old/

	cat out.json

	rm old -r
	rm new -r
done

jq -r 'to_entries[] | "\(.key)#\(.value.changedMethods | keys[])"' out.json
