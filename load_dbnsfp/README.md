load_dbnsfp
=========

An example loader script and schema for the dbNSFP dataset. 
For more information about the project, please visit http://www.sites.google.com/site/jpopgen/dbNSFP

The file dbnsfp_example_20k.gz has been created by selecting the first 20,000 rows from one of the dbNSFP3.0b2c files.
Provided for illustration.

 - recreate_dbnsfp.sh erases any existing arrays nad rebuilds the schema
 - load_file.sh adds a new file to the schema

Example workflow:
 
 1. install and start scidb
 2. install load_tools (see http://github.com/paradigm4/load_tools)
 3. ./recreate_db.sh
 4. ./load_file.sh [dbNSFP file]
 5. iquery -aq "project(between(DBNSFP_VARIANT, 9,422860,null, 9,422870,null), ref, alt, SIFT_converted_rankscore, MutationAssessor_rankscore)"
 
