Genomic Variant Data Warehouse
=========

This repository has been constructed to organize the functions to load and process variant datasets and provide other functionality to facilitate the exploration of the publicly available variant datasets in general. A few of the scripts may still be prototype. These can be adapted quickly for a variety of purposes and your particular use case. 

In the base directory(variant_warehouse) are examples of loading and processing Genomic Variant Datasets in SciDB, currently built around the 1000 Genomes dataset. (http://www.1000genomes.org)

Part of the original prototype was adapted from scidb-genotypes by Douglas Slotta (NCBI)
(http://www.ncbi.nlm.nih.gov/variation/tools/1000genomes/)
See: https://github.com/slottad/scidb-genotypes

These scripts were created for SciDB 14.12 or newer. The larger the cluster - the faster these will run as they are designed for scalability. The load_tools plugin is required for a vast majority of the examples. See: www.github.com/paradigm4/load_tools

##Data Loaders for Various Common Datasets

 * load_gene_37: simple gene symbols and positions according to GRCh37
 * load_1000g: the 1000 Genomes Project phase 3: http://www.1000genomes.org/
 * load_esp: the Exome Sequencing Project: http://evs.gs.washington.edu/EVS/
 * load_dbnsfpv2.9: the dbNSFP Project (version 2.9): https://sites.google.com/site/jpopgen/dbNSFP
 * load_dbnsfpv3: the dbNSFP Project (version 3.0)
 * load_gvcf: for the Broad's GVCF format: https://www.broadinstitute.org/gatk/guide/article?id=4017

Below are examples of demonstration code for variant processing use cases. 

##Use Case Demonstration

### vcf_toolkit.R
A set of example queries using 1000 Genomes and ESP data using R. Includes sample lookups, allele counts, PCA plot, range joins.

### example_afl_scripts
Some sample queries in AFL, including grouped allele count and a join of ESP and 1000 Genomes.

### shiny_browser
A variant browser app that computes allele counts grouped by major population and makes an interactive plot.

### shiny_tcga_dbnsfp
An app that can filter and plot TCGA alteration frequencies filtered against dbNSFP scores, as well as clinical keywords. You need to have TCGA data loaded in order to run it - you can use the AMI, for example.

### AMI
Some examples are shown in the Bioinformatics AMI. Last updated June 2015. Instructions for that are here: http://www.paradigm4.com/try_scidb/

##Spark Benchmark

The Benchmark comprises common genomic processing queries to highlight the differences between SciDB and Spark-Adam.  The code for the spark benchmark is located in variant_warehouse/spark_benchmark.

