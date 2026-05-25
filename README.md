# Defects4j LLM Automate

This repo examines how LLMs can fix defects4j bugs in two variants: Without any additional information and with bug location information.

## Prerequisites
- docker installed
- `defects4j-repos-v3.zip` downloaded (might be downloaded during the process, but if multiple experiments should be started, that will significantly slow it down)

## Basic

To execute the basic configuration, run the following steps:

- `HOME=/tmp docker build -t "repairer" .`
- `CONTAINER=$(docker run -td repairer)`
- `docker cp defects4j-repos-v3.zip $CONTAINER:/home/defects4j/project_repos`

Attach do the container (`docker exec -it $CONTAINER bash`) and run the following steps:
- `cd /home/defects4j && ./init.sh`
- `cd project_repos/ && unzip defects4j-repos-v3.zip && mv defects4j/project_repos/* .`
- `curl -fsSL https://opencode.ai/install | bash`

By default, it is assumed that ollama is running on 172.17.0.1:11430 and gemma4:31b should be used; if this is not the case, configure `~/.config/opencode/opencode.json`.

Finally, start the experiment using `cd /home/defects4j-automate && ./promptBasic.sh`

## Bug Location Information

TODO
