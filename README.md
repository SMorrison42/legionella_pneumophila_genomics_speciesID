# legionella_pneumophila_genomics_speciesID

## Project Description
This docker container performs in silico Legionella spp. identification from Illumina Paired end reads and De novo assemblies. The input file formats are .fastq (for Illumina raw sequencing data) or .fasta/.fa./.fas (for De novo assemblies).

Note: The Mash sketch database file exceed the file size for GitHub. There is a list of all the genomes used to generate the Mash sketch in the /db directory of this repo.  The Docker container does contain the entire Mash sketch.

## Dependencies 
Mash/2.0.0

Perl/5.22.1

## Usage

Docker: 

Illumina Paired End:
```
docker run -v <your input directory complete path>:/<directory in container> --privileged smorrison42/speciesid:0.1 -fastq1 /<directory in container>/R1.fastq -fastq2 /<directory in container>/R2.fastq -quiet > results.
```
Denovo Assemblies:
```
docker run -v <your input directory complete path>:/<directory in container> --privileged smorrison42/speciesid:0.1 -fasta /<directory in container>/<denovo assembly file> -quiet > results.txt
 ``` 
  ## Developed by
  
  Jason Caravas 
  
  [Shatavia Morrison](https://github.com/SMorrison42)
  
  
  
