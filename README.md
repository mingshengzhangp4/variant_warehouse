vcf_tools
=========

Prototype for loading VCF Datasets into SciDB, currently built around the 1000 Genomes dataset.
Very very early, unstable. Work in progress.

Part of the original prototype was adapted from scidb-genotypes by Douglas Slotta (NCBI)
See: https://github.com/slottad/scidb-genotypes

These scripts were created for SciDB 14.12 or newer. The larger the cluster - the faster these will run. The load_tools plugin is required for a vast majority of the examples. See: www.github.com/paradigm4/load_tools

## kg_loader: Based on the 1000 Genomes Dataset
Built to load 1000 Genomes Phase 3 data or data with very similar organization.
Recently updated with a more useful schema. See README inside the kg_loader directory for more information.

## R toolkit
Currently in the process of being revamped.

## AMI
Some older VCF examples are shown in the Bioinformatics AMI. Instructions for that are here: http://www.paradigm4.com/try_scidb/

## gvcf: Tools for loading and processing gvcf files
Work in progress
