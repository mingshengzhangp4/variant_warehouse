#!/bin/bash

DATE="2015_06_01"

iquery -anq "remove(TCGA_${DATE}_TUMOR_TYPE_STD)"   > /dev/null 2>&1
iquery -anq "remove(TCGA_${DATE}_SAMPLE_TYPE_STD)"  > /dev/null 2>&1
iquery -anq "remove(TCGA_${DATE}_SAMPLE_STD)"       > /dev/null 2>&1
iquery -anq "remove(TCGA_${DATE}_PATIENT_STD)"      > /dev/null 2>&1
iquery -anq "remove(TCGA_${DATE}_CLINICAL_STD)"     > /dev/null 2>&1

iquery -aq "create array TCGA_${DATE}_TUMOR_TYPE_STD  <tumor_type_name:string> [tumor_type_id]"
iquery -aq "create array TCGA_${DATE}_SAMPLE_TYPE_STD <code:string,definition:string,short_letter_code:string> [sample_type_id]"
iquery -aq "create array TCGA_${DATE}_SAMPLE_STD <sample_name:string> [tumor_type_id=0:*,1,0, patient_id=0:*,1000,0, sample_type_id=0:*,1,0,sample_id=0:*,1000,0]"
iquery -aq "create array TCGA_${DATE}_PATIENT_STD  <patient_name:string> [tumor_type_id=0:*,1,0,patient_id=0:*,1000,0]"
iquery -aq "create array TCGA_${DATE}_CLINICAL_STD <key:string,value:string null> [tumor_type_id=0:*,1,0,clinical_line_nbr=0:*,1000,0,patient_id=0:*,1000,0]"

MYDIR=`pwd`
iquery -anq "load(TCGA_${DATE}_SAMPLE_TYPE_STD, '$MYDIR/sample_type.tsv', 0, 'tsv')"
iquery -anq "load(TCGA_${DATE}_TUMOR_TYPE_STD, '$MYDIR/tumor_type.tsv', 0, 'tsv')"
