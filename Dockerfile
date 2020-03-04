FROM ubuntu:14.04

MAINTAINER Shatavia Morrison
MAINTAINER Jason Caravas


RUN apt-get update && \
    apt-get -y install wget && \
    apt-get clean

RUN wget https://github.com/marbl/Mash/releases/download/v2.0/mash-Linux64-v2.0.tar && \
    tar -xvf mash-Linux64-v2.0.tar && \
    rm -rf mash-Linux64-v2.0.tar

 
ENV PATH="${PATH}:/mash-Linux64-v2.0" \
    LC_ALL=C

COPY db/ db
COPY scripts/ scripts

ENTRYPOINT ["perl","/scripts/species_id_tool_agave_3-miseq.pl"]


