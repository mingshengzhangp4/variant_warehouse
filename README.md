variant_warehouse
=========

Examples of loading and processing Genomic Variant Datasets in SciDB, currently built around the 1000 Genomes dataset.
Very very early, unstable. Work in progress.

Part of the original prototype was adapted from scidb-genotypes by Douglas Slotta (NCBI)
See: https://github.com/slottad/scidb-genotypes

These scripts were created for SciDB 14.12 or newer. The larger the cluster - the faster these will run. The load_tools plugin is required for a vast majority of the examples. See: www.github.com/paradigm4/load_tools

### gene_37: a simple set of gene locations
A tsv and a loader script to create a very simple array of gene positions, used in some queries.

### load_1000g: for the 1000 Genomes Dataset
Scripts to load the Phase 3 VCF data or data with very similar organization.
[Click here](https://github.com/Paradigm4/variant_warehouse/tree/master/load_1000g) for more information.

### R toolkit
Currently in the process of being revamped.

### AMI
Some older VCF examples are shown in the Bioinformatics AMI. Instructions for that are here: http://www.paradigm4.com/try_scidb/

### load_gvcf: Tools for loading and processing GVCF files
Work in progress
