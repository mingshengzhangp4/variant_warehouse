kg_loader
=========

An example loader script and schema for the 1000 Genomes Phase 3 dataset. 
For more information about the project, please visit http://www.1000genomes.org/ 

The file example20k.vcf.gz has been created by selecting the first 20,000 rows from one of the VCF files. 
The file populations.tsv was created by selecting two of the columns from the sample description panel file. 
Both of these are provided as small illustrative examples.

 - recreate_db.sh erases any existing arrays nad rebuilds the schema
 - load_file.sh adds a VCF file to the schema
 - load_populations.sh loads the additional superpopulation data in a very simple object

Example workflow:
 
 1. install and start scidb
 2. install load_tools (see http://github.com/paradigm4/load_tools)
 3. ./recreate_db.sh
 4. ./load_file.sh [VCF file]
 5. ./load_file.sh [another VCF file]
 6. ./load_populations.sh
 
 
