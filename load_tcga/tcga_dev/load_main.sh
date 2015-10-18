#!/bin/bash

 
if [ $# -ne 3 ]; then
    echo "need two  arguments:"
    echo "1.  script path,  such as:  /home/mzhang/Paradigm4_labs/variant_warehouse/load_tcga/tcga_dev"
    echo "2.  geneFile, such as: /home/mzhang/Paradigm4_labs/variant_warehouse/load_gene_37/tcga_python_pipe/newGene.tsv"
    echo "3. Date, such as: 2015_06_01"
    exit 1
fi



current_wd=$1
gene_file=$2
DATE=$3

logfile=${current_wd}/loader_log.txt
rm -f ${logfile}
exec > >(tee ${logfile})
exec 2>&1


bash  $1/tcga_array_initialization.sh $1

# load gene list 
bash $1/load_gene.sh ${DATE} $2

#   echo "start cnv data loading @ `date`"
#   for tumor_type in `cat tumor_type.tsv`; do
#     bash $1/load_cnv.sh $3 $tumor_type $1 $2
#   done
#   echo "finished loading cnv data @ `date`"


#   echo "start clinical data loading @ `date`"
#   for tumor_type in `cat tumor_type.tsv`; do
#     bash $1/load_clinical_ming.sh $3 $tumor_type $1
#   done
#   echo "finished loading clinical data @ `date`"


#   echo "start RNA seq loading @: `date`"
#     for tumor_type in `cat tumor_type.tsv`; do
#       bash $1/load_RNAseqV2.sh $3 $tumor_type $1
#     done
#   echo "finished RNA seq loading @: `date`"

#   echo "start methylation loading @: `date`"
#     for tumor_type in `cat tumor_type.tsv`; do
#       bash $1/load_methylation.sh $3 $tumor_type $1
#     done

##echo "start loading methylation data @ `date`"
## bash $1/load_methylation.sh $3 ACC 
## bash $1/load_methylation.sh $3 BLCA 
## bash $1/load_methylation.sh $3 BRCA 
## bash $1/load_methylation.sh $3 CESC 
## bash $1/load_methylation.sh $3 CHOL
## bash $1/load_methylation.sh $3 COAD
## bash $1/load_methylation.sh $3 COADREAD
## bash $1/load_methylation.sh $3 GBM 
## bash $1/load_methylation.sh $3 GBMLGG 
## bash $1/load_methylation.sh $3 HNSC 
## bash $1/load_methylation.sh $3 KICH 
## bash $1/load_methylation.sh $3 KIPAN
## bash $1/load_methylation.sh $3 KIRC 
## bash $1/load_methylation.sh $3 KIRP 
## bash $1/load_methylation.sh $3 LAML 
## bash $1/load_methylation.sh $3 LGG 
## bash $1/load_methylation.sh $3 LIHC 
## bash $1/load_methylation.sh $3 LUAD 
## bash $1/load_methylation.sh $3 LUSC 
## bash $1/load_methylation.sh $3 OV 
## bash $1/load_methylation.sh $3 PAAD 
## bash $1/load_methylation.sh $3 PCPG
## bash $1/load_methylation.sh $3 PRAD 
## bash $1/load_methylation.sh $3 READ 
## bash $1/load_methylation.sh $3 SARC 
## bash $1/load_methylation.sh $3 SKCM 
## bash $1/load_methylation.sh $3 STAD 
## bash $1/load_methylation.sh $3 THCA 
## bash $1/load_methylation.sh $3 UCEC 
## bash $1/load_methylation.sh $3 UCS 
## bash $1/load_methylation.sh $3 UVM 
## echo "finished loading methylation data @`date`"


echo "start loading mutation data @ `date`"
bash $1/load_mutation_ming.sh $3 $1 ACC 39 40
bash $1/load_mutation_ming.sh $3 $1 BLCA 40 42
bash $1/load_mutation_ming.sh $3 $1 BRCA 49 50
bash $1/load_mutation_ming.sh $3 $1 CESC 49 50
bash $1/load_mutation_ming.sh $3 $1 CHOL 39 40
bash $1/load_mutation_ming.sh $3 $1 COAD 35 36
bash $1/load_mutation_ming.sh $3 $1 COADREAD 35 36
bash $1/load_mutation_ming.sh $3 $1 GBM 40 42
bash $1/load_mutation_ming.sh $3 $1 GBMLGG 40 42
bash $1/load_mutation_ming.sh $3 $1 HNSC 40 42
bash $1/load_mutation_ming.sh $3 $1 KICH 40 42
bash $1/load_mutation_ming.sh $3 $1 KIPAN 39 40
bash $1/load_mutation_ming.sh $3 $1 KIRC 39 40
bash $1/load_mutation_ming.sh $3 $1 KIRP 39 40
bash $1/load_mutation_ming.sh $3 $1 LAML 49 50
bash $1/load_mutation_ming.sh $3 $1 LGG 49 50
bash $1/load_mutation_ming.sh $3 $1 LIHC 39 40
bash $1/load_mutation_ming.sh $3 $1 LUAD 40 42
bash $1/load_mutation_ming.sh $3 $1 LUSC 40 42
bash $1/load_mutation_ming.sh $3 $1 OV 40 42
bash $1/load_mutation_ming.sh $3 $1 PAAD 40 42
bash $1/load_mutation_ming.sh $3 $1 PCPG 40 42
bash $1/load_mutation_ming.sh $3 $1 PRAD 40 42
bash $1/load_mutation_ming.sh $3 $1 READ 35 36
bash $1/load_mutation_ming.sh $3 $1 SARC 49 50
bash $1/load_mutation_ming.sh $3 $1 SKCM 40 42
bash $1/load_mutation_ming.sh $3 $1 STAD 40 42
bash $1/load_mutation_ming.sh $3 $1 THCA 40 42
bash $1/load_mutation_ming.sh $3 $1 UCEC 100 38
bash $1/load_mutation_ming.sh $3 $1 UCS 40 42
bash $1/load_mutation_ming.sh $3 $1 UVM 40 42
echo "finished loading mutation data @`date`"

