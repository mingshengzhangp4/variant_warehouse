vcf_tools
=========

Prototype for loading VCF Datasets into SciDB, currently built around the 1000 Genomes dataset.
Very very early, unstable. Work in progress.

Part of the original prototype was adapted from scidb-genotypes by Douglas Slotta (NCBI)
See: https://github.com/slottad/scidb-genotypes

# kg_loader: Based on the 1000 Genomes Dataset
Built to load 1000 Genomes data or data with very similar organization.
Recently updated with a more useful schema.

## Pre-reqs
0. Assumes running SciDB 14.12 or newer. The larger the cluster - the faster this will run. 
1. Install load_tools from www.github.com/paradigm4/load_tools
2. load_file.sh is just a shell script, it takes advantage of some quirks of 1000Genomes, but also deals with some complexity seen in that dataset. Depending on the dataset, the script may need adjustments.

## Loading
1. Run ./kg_loader/recreate_db.sh once initially to create all the target arrays; run it again to blow away all the data
2. Run ./kg_loader/load_file.sh FILENAME
3. Hang onto something

## R toolkit
Currently in the process of being revamped.

## AMI
A slightly older version of this is packaged into the Bioinformatics AMI. Instructions for that are here: http://www.paradigm4.com/try_scidb/

# gvcf: Tools for loading and processing gvcf files
Work in progress
