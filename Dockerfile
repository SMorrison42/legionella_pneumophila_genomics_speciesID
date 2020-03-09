FROM ubuntu:14.04

MAINTAINER Shatavia Morrison
MAINTAINER Jason Caravas

COPY db/ db
COPY scripts/ scripts


RUN apt-get update && \
    apt-get -y install wget && \
    apt-get clean

RUN wget https://github.com/marbl/Mash/releases/download/v2.0/mash-Linux64-v2.0.tar && \
    tar -xvf mash-Linux64-v2.0.tar && \
    rm -rf mash-Linux64-v2.0.tar


ENV PATH="${PATH}:/mash-Linux64-v2.0" \
    LC_ALL=C

RUN chmod 755 db/MASH_Legionella_master_sketch_2018-02-12_100k.msh
RUN chmod 755 scripts/species_id_tool_agave_3-miseq.pl


CMD ["perl","/scripts/species_id_tool_agave_3-miseq.pl"]


