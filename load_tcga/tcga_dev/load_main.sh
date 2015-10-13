#!/bin/bash

current_wd=`pwd`
logfile=${current_wd}/loader_log.txt
rm -f ${logfile}
exec > >(tee ${logfile})
exec 2>&1


bash  ./recreate_db_ming.sh /home/scidb/variant_warehouse/load_gene_37/newGene.tsv

## echo "start clinical data loading @ `date`"
## for tumor_type in `cat tumor_type.tsv`; do
##   ./load_clinical_ming.sh 2015_06_01 $tumor_type
## done
## echo "finished loading clinical data @ `date`"
## 
## 
## echo "start RNA seq loading @: `date`"
##   for tumor_type in `cat tumor_type.tsv`; do
##     ./load_RNAseqV2.sh 2015_06_01 $tumor_type
##   done
## echo "finished RNA seq loading @: `date`"

## echo "start methylation loading @: `date`"
##   for tumor_type in `cat tumor_type.tsv`; do
##     ./load_methylation.sh 2015_06_01 $tumor_type
##   done

echo "start loading methylation data @ `date`"
## bash ./load_methylation.sh 2015_06_01 ACC 
## bash ./load_methylation.sh 2015_06_01 BLCA 
## bash ./load_methylation.sh 2015_06_01 BRCA 
## bash ./load_methylation.sh 2015_06_01 CESC 
## bash ./load_methylation.sh 2015_06_01 CHOL
## bash ./load_methylation.sh 2015_06_01 COAD
bash ./load_methylation.sh 2015_06_01 COADREAD
bash ./load_methylation.sh 2015_06_01 GBM 
bash ./load_methylation.sh 2015_06_01 GBMLGG 
bash ./load_methylation.sh 2015_06_01 HNSC 
bash ./load_methylation.sh 2015_06_01 KICH 
bash ./load_methylation.sh 2015_06_01 KIPAN
bash ./load_methylation.sh 2015_06_01 KIRC 
bash ./load_methylation.sh 2015_06_01 KIRP 
bash ./load_methylation.sh 2015_06_01 LAML 
bash ./load_methylation.sh 2015_06_01 LGG 
bash ./load_methylation.sh 2015_06_01 LIHC 
bash ./load_methylation.sh 2015_06_01 LUAD 
bash ./load_methylation.sh 2015_06_01 LUSC 
bash ./load_methylation.sh 2015_06_01 OV 
bash ./load_methylation.sh 2015_06_01 PAAD 
bash ./load_methylation.sh 2015_06_01 PCPG
bash ./load_methylation.sh 2015_06_01 PRAD 
bash ./load_methylation.sh 2015_06_01 READ 
bash ./load_methylation.sh 2015_06_01 SARC 
bash ./load_methylation.sh 2015_06_01 SKCM 
bash ./load_methylation.sh 2015_06_01 STAD 
bash ./load_methylation.sh 2015_06_01 THCA 
bash ./load_methylation.sh 2015_06_01 UCEC 
bash ./load_methylation.sh 2015_06_01 UCS 
bash ./load_methylation.sh 2015_06_01 UVM 
echo "finished loading methylation data @`date`"


echo "finished methylation loading @: `date`"

## echo "start loading mutation data @ `date`"
## bash ./load_mutation_ming.sh 2015_06_01 ACC 39 40
## bash ./load_mutation_ming.sh 2015_06_01 BLCA 40 42
## bash ./load_mutation_ming.sh 2015_06_01 BRCA 49 50
## bash ./load_mutation_ming.sh 2015_06_01 CESC 49 50
## bash ./load_mutation_ming.sh 2015_06_01 CHOL 39 40
## bash ./load_mutation_ming.sh 2015_06_01 COAD 35 36
## bash ./load_mutation_ming.sh 2015_06_01 COADREAD 35 36
## bash ./load_mutation_ming.sh 2015_06_01 GBM 40 42
## bash ./load_mutation_ming.sh 2015_06_01 GBMLGG 40 42
## bash ./load_mutation_ming.sh 2015_06_01 HNSC 40 42
## bash ./load_mutation_ming.sh 2015_06_01 KICH 40 42
## bash ./load_mutation_ming.sh 2015_06_01 KIPAN 39 40
## bash ./load_mutation_ming.sh 2015_06_01 KIRC 39 40
## bash ./load_mutation_ming.sh 2015_06_01 KIRP 39 40
## bash ./load_mutation_ming.sh 2015_06_01 LAML 49 50
## bash ./load_mutation_ming.sh 2015_06_01 LGG 49 50
## bash ./load_mutation_ming.sh 2015_06_01 LIHC 39 40
## bash ./load_mutation_ming.sh 2015_06_01 LUAD 40 42
## bash ./load_mutation_ming.sh 2015_06_01 LUSC 40 42
## bash ./load_mutation_ming.sh 2015_06_01 OV 40 42
## bash ./load_mutation_ming.sh 2015_06_01 PAAD 40 42
## bash ./load_mutation_ming.sh 2015_06_01 PCPG 40 42
## bash ./load_mutation_ming.sh 2015_06_01 PRAD 40 42
## bash ./load_mutation_ming.sh 2015_06_01 READ 35 36
## bash ./load_mutation_ming.sh 2015_06_01 SARC 49 50
## bash ./load_mutation_ming.sh 2015_06_01 SKCM 40 42
## bash ./load_mutation_ming.sh 2015_06_01 STAD 40 42
## bash ./load_mutation_ming.sh 2015_06_01 THCA 40 42
## bash ./load_mutation_ming.sh 2015_06_01 UCEC 100 38
## bash ./load_mutation_ming.sh 2015_06_01 UCS 40 42
## bash ./load_mutation_ming.sh 2015_06_01 UVM 40 42
## echo "finished loading mutation data @`date`"

