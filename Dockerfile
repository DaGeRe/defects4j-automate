FROM ubuntu:26.04

RUN apt update && apt install -y git openjdk-11-jdk cpanminus build-essential
RUN apt install -y libdbi-perl libdbd-csv-perl libperl-critic-perl libjson-parse-perl libstring-interpolate-perl

RUN git clone https://github.com/rjust/defects4j
RUN cd defects4j && cpanm --installdeps .
