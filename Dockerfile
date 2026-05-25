FROM ubuntu:26.04

RUN apt update && apt install -y git openjdk-11-jdk cpanminus build-essential maven
RUN apt install -y libdbi-perl libdbd-csv-perl libperl-critic-perl libjson-parse-perl libstring-interpolate-perl
RUN apt install -y curl vim unzip locales

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

RUN cd /home && git clone https://github.com/rjust/defects4j
RUN cd /home/defects4j && cpanm --installdeps .

COPY defects4j-repos-v3.zip /home/defects4j/project_repos
RUN cd /home/defects4j/project_repos/ && unzip defects4j-repos-v3.zip && mv defects4j/project_repos/* .

RUN curl -fsSL https://opencode.ai/install | bash

COPY promptBasic.sh /home/defects4j-automate/
COPY promptWithLocalBugInformation.sh /home/defects4j-automate/
RUN chmod +x /home/defects4j-automate/promptBasic.sh
RUN chmod +x /home/defects4j-automate/promptWithLocalBugInformation.sh

COPY opencode.json /root/.config/opencode/opencode.json

ENV PATH="${PATH}:/home/defects4j/framework/bin"
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
