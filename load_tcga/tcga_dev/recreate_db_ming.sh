#!/bin/bash

DATE="2015_06_01"
MYDIR=`pwd`

iquery -anq "remove(TCGA_${DATE}_TUMOR_TYPE_STD)"   > /dev/null 2>&1
iquery -anq "remove(TCGA_${DATE}_SAMPLE_TYPE_STD)"  > /dev/null 2>&1
iquery -anq "remove(TCGA_${DATE}_SAMPLE_STD)"       > /dev/null 2>&1
iquery -anq "remove(TCGA_${DATE}_PATIENT_STD)"      > /dev/null 2>&1
iquery -anq "remove(TCGA_${DATE}_CLINICAL_STD)"     > /dev/null 2>&1
iquery -anq "remove(TCGA_${DATE}_GENE_STD)"         > /dev/null 2>&1
iquery -anq "remove(TCGA_${DATE}_MUTATION_STD)"     > /dev/null 2>&1


iquery -aq "create array TCGA_${DATE}_TUMOR_TYPE_STD  <tumor_type_name:string> [tumor_type_id]"



iquery -aq "create array TCGA_${DATE}_SAMPLE_TYPE_STD <code:string,definition:string,short_letter_code:string> [sample_type_id]"
iquery -aq "create array TCGA_${DATE}_SAMPLE_STD <sample_name:string> [tumor_type_id=0:*,1,0, patient_id=0:*,1000,0, sample_type_id=0:*,1,0,sample_id=0:*,1000,0]"
iquery -aq "create array TCGA_${DATE}_PATIENT_STD  <patient_name:string> [tumor_type_id=0:*,1,0,patient_id=0:*,1000,0]"



iquery -aq "create array TCGA_${DATE}_CLINICAL_STD <key:string,value:string null> [tumor_type_id=0:*,1,0,clinical_line_nbr=0:*,1000,0,patient_id=0:*,1000,0]"

iquery -aq "create array TCGA_${DATE}_GENE_STD 
 <gene_symbol:string,
  genomic_start:uint64,
  genomic_end:uint64,
  strand:char,
  locus_tag:string,
  synonyms:string,
  dbXrefs:string,
  map_location:string,
  description:string,
  type_of_gene:string,
  chromosome_nbr:uint64> 
[gene_id=0:*,10000,0]"

iquery -aq "create array TCGA_${DATE}_MUTATION_STD
 <GRCh_release:string null,
  mutation_genomic_chr:string null,
  mutation_genomic_start:int64 null,
  mutation_genomic_end:int64 null,
  mutation_type: string null,
  variant_type: string null,  
  reference_allele:string null,
  tumor_allele:string null,
  c_pos_change:string null,
  p_pos_change:string null>
 [tumor_type_id=0:*,1,0,
  gene_id=0:*,10000,0,
  sample_id=0:*,1000,0,
  mutation_id=0:*,100000,0]"

iquery -aq "create array TCGA_${DATE}_RNAseqV2_STD
 <RNA_expressionLevel:double null>
 [tumor_type_id=0:*,1,0,
  gene_id=0:*,10000,0,
  sample_id=0:*,1000,0]"

MYDIR=`pwd`
iquery -anq "load(TCGA_${DATE}_SAMPLE_TYPE_STD, '$MYDIR/sample_type.tsv', 0, 'tsv')"


iquery -anq "load(TCGA_${DATE}_TUMOR_TYPE_STD, '$MYDIR/tumor_type.tsv', 0, 'tsv')"


iquery -anq "load(TCGA_${DATE}_GENE_STD, '$MYDIR/gene.tsv', 0, 'tsv')"

##  echo "so far so good. Continue?"
##  select yn in "yes" "no"; do
##      case $yn in
##          yes) break;;
##          no) exit 1 ;;
##      esac
##  done


