# legionella_pneumophila_genomics_speciesID

## Project Description
This docker container performs in silico Legionella spp. identification from Illumina Paired end reads and De novo assemblies. The input file formats are .fastq (for Illumina raw sequencing data) or .fasta/.fa./.fas (for De novo assemblies).

Note: The Mash sketch database file exceed the file size for GitHub. There is a list of all the genomes used to generate the Mash sketch in the /db directory of this repo.  The Docker container does contain the entire Mash sketch. Please create an image of the container. If you try to build the container from the source it will fail since the Mash Sketch is not in this repo.

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
  
  [Jason Caravas](https://github.com/jacaravas) 
  
  [Shatavia Morrison](https://github.com/SMorrison42)
  
  
  ## License

The repository utilizes code licensed under the terms of the Apache Software License and therefore is licensed under ASL v2 or later.

This source code in this repository is free: you can redistribute it and/or modify it under the terms of the Apache Software License version 2, or (at your option) any later version.

This source code in this repository is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Apache Software License for more details.

You should have received a copy of the Apache Software License along with this program. If not, see http://www.apache.org/licenses/LICENSE-2.0.html

The source code forked from other open source projects will inherit its license.

## Privacy

This repository contains only non-sensitive, publicly available data and information. All material and community participation is covered by the Surveillance Platform Disclaimer and Code of Conduct. For more information about CDC's privacy policy, please visit http://www.cdc.gov/privacy.html.

## Contributing

Anyone is encouraged to contribute to the repository by forking and submitting a pull request. (If you are new to GitHub, you might start with a basic tutorial.) By contributing to this project, you grant a world-wide, royalty-free, perpetual, irrevocable, non-exclusive, transferable license to all users under the terms of the Apache Software License v2 or later.

All comments, messages, pull requests, and other submissions received through CDC including this GitHub page are subject to the Presidential Records Act and may be archived. Learn more at http://www.cdc.gov/other/privacy.html.

## Records

This repository is not a source of government records, but is a copy to increase collaboration and collaborative potential. All government records will be published through the CDC web site.

## Notices

Please refer to CDC's Template Repository for more information about contributing to this repository, public domain notices and disclaimers, and code of conduct.

