# Defects4j LLM Automate

This repo examines how LLMs can fix defects4j bugs in two variants: Without any additional information and with bug location information.

## Prerequisites
- docker installed
- `defects4j-repos-v3.zip` downloaded (might be downloaded during the process, but if multiple experiments should be started, that will significantly slow it down)

## Basic

To execute the basic configuration, run the following steps:

- `HOME=/tmp docker build -t "repairer" .`
- `CONTAINER=$(docker run -td repairer)`

Attach do the container (`docker exec -it $CONTAINER bash`) and run the following steps:
- `cd /home/defects4j && ./init.sh`

By default, it is assumed that ollama is running on 172.17.0.1:11430 and gemma4:31b should be used; if this is not the case, configure `~/.config/opencode/opencode.json`.

Finally, start the experiment using `cd /home/defects4j-automate && ./promptBasic.sh`

## Trace Location Information

For getting the trace information, it is mostly easier to use the host machine. No LLM infrastructure is required, so this can be done relatively easy and fast locally (takes a few hours for executing all tests with and without tracing).

To do so, execute the following steps:
- Install `cpan`, cpanm and JDK 11; it needs to be 11 for defects4j. (For Rocky/Fedora: `sudo dnf install cpan java-11-openjdk-devel && sudo cpan App::cpanminus`)
- Prepare defects4j itself: `git clone https://github.com/rjust/defects4j && cd defects4j && cpanm --installdeps . && ./init.sh`
- Export the path for defects4j: `export PATH=$PATH:$(pwd)/framework/bin`
- Prepare String interpolate: `eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib) && cpanm String::Interpolate`
- Get this repo: `git clone https://github.com/DaGeRe/defects4j-automate.git && cd defects4j-automate/`
- Get all trace information: `for PROJECT in Cli Compress JacksonCore JacksonDatabind Lang Math Time; do ./getCallTreeSizes.sh $PROJECT; done`

This yields a `tracelength.txt`, that contains `TraceLength`, `uniquemethods`, `maxdepth` (of the call tree) and `topLevelCalls` (of the test). This will be executed for the first test case (by surefires testcase sorting); if a test class has multiple methods, all methods are executed.

### Analysis

To analyze this, different variants exist:

- Plot the Steps / Token relation for individual fixes: Call `../analyzeStepsRaw.sh &> raw.txt` and `gnuplot -c plot.plt`.
- Get correlation matrix per project: `for project in Lang JacksonDatabind Jsoup; do for mode in uninformed semi-informed informed; do echo $project"-"$mode; Rscript -e "d <- read.table('"results-$project-$mode.csv"', header=TRUE); options(width=200); print(cor(d))"; done; done`
- Get correlations matrix per mode: `for mode in uninformed semi-informed informed; do echo $mode; cat results-*-"$mode".csv | grep -v "BugID" &> merged_$mode.csv; Rscript -e "d <- read.table('"merged_$mode.csv"', header=TRUE); options(width=200); print(cor(d))"; done;`
