Geonomic Variant Data Warehouse
=========
With SciDB's MAC technology and other critical architecture features made for multi-user large dataset exploration prowess, it is poised to become the premier variant warehouse computational database management system solution. http://www.paradigm4.com

This repository has been constructed to organize the functions to load and process Variant datasets and provide other functionality to facilitate the exploration of the publicly available variant datasets in general. A few of the scripts may be of demo or prototype quality, but can be adapted quickly for a variety of purposes and your particular use case. 

In the base directory(variant_warehouse) are examples of loading and processing Genomic Variant Datasets in SciDB, currently built around the 1000 Genomes dataset. (http://www.1000genomes.org)

Part of the original prototype was adapted from scidb-genotypes by Douglas Slotta (NCBI)
(http://www.ncbi.nlm.nih.gov/variation/tools/1000genomes/)
See: https://github.com/slottad/scidb-genotypes

These scripts were created for SciDB 14.12 or newer. The larger the cluster - the faster these will run as they are designed for scalability. The load_tools plugin is required for a vast majority of the examples. See: www.github.com/paradigm4/load_tools

Below are the data loading scripts found in the base directory(variant_warehouse):

##Data Loading

### load_gene_37: a simple set of gene locations
A tsv and a loader script to create a very simple array of gene positions, used in some queries.

### load_1000g: for the 1000 Genomes Dataset
Scripts to load the Phase 3 VCF data or data with very similar organization.
[Click here](https://github.com/Paradigm4/variant_warehouse/tree/master/load_1000g) for more information.

### load_ESP: for the Exome Sequencing Project Dataset
Scripts to load ESP data, similar to load_1000g in nature.

### load_gvcf: for the GVCF format

Below are examples of demonstration code for variant processing use cases. 
##Use Case Demonstration

### vcf_toolkit.R
A set of example queries using 1000 Genomes and ESP data using R. Includes sample lookups, allele counts, PCA plot, range joins.

### example_afl_scripts
Some sample queries in AFL, including grouped allele count and a join of ESP and 1000 Genomes.

### shiny_browser
A variant browser app that computes allele counts grouped by major population and makes an interactive plot.

### AMI
Some older VCF examples are shown in the Bioinformatics AMI. Instructions for that are here: http://www.paradigm4.com/try_scidb/

##Spark Benchmark



