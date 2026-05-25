# Defects4j LLM Automate

This repo examines how LLMs can fix defects4j bugs in two variants: Without any additional information and with bug location information.

## Basic

To execute the basic configuration, run the following steps:

- `HOME=/tmp docker build -t "repairer" .`
- `CONTAINER=$(docker run -td repairer)`
- `docker cp defects4j-repos-v3.zip $CONTAINER:/home/defects4j/project_repos`

Attach do the container an run the following steps:
- `cd /home/defects4j && ./init.sh`
- 

## Bug Location Information

TODO
