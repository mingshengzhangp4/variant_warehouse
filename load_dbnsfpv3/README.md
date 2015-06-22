load_dbnsfpv3
=========

An example loader script and schema for the dbNSFP dataset, version 3.0b2c.
For more information about the project, please visit http://www.sites.google.com/site/jpopgen/dbNSFP
Please consult the website for terms of use for dbNSFP and related data.

The file dbnsfp_example_20k.gz has been created by selecting the first 20,000 rows from one of the dbNSFP3.0b2c files.
Provided for illustration only.

 - recreate_dbnsfp.sh erases any existing arrays nad rebuilds the schema
 - load_file.sh adds a new file to the schema

Example workflow:
 
 1. install and start scidb
 2. install load_tools (see http://github.com/paradigm4/load_tools)
 3. ./recreate_dbnsfpv3.sh
 4. ./load_dbnsfpv3.sh [dbNSFP file]
 5. iquery -aq "project(between(DBNSFP_V3_VARIANT, 9,422860,null, 9,422870,null), ref, alt, SIFT_converted_rankscore, MutationAssessor_rankscore)"
 
Note: dbnsfp version 3 is created using the GRCh38 reference assembly. The other datasets in this repostory use 37.
