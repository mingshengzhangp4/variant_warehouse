#!/bin/bash

 
if [ $# -ne 3 ]; then
    echo "need three  arguments:"
    echo "1.  script path,  such as:  /home/scidb/variant_warehouse/load_tcga/tcga_dev"
    echo "2.  geneFile, such as: /home/scidb/variant_warehouse/load_gene_37/tcga_python_pipe/newGene.tsv"
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



m_gene_file=$1/gene_symbol_as_id.tsv
python gene_symbol_geneID_generator ${gene_file} ${m_gene_file}
 
# load gene list 
bash $1/load_gene.sh ${DATE} ${m_gene_file}


###   many files are too big to be parsed by python, to-do list #
###    echo "start cnv data loading @ `date`"
###    for tumor_type in `cat tumor_type.tsv`; do
###      bash $1/load_cnv.sh $3 $tumor_type $1 $2
###    done
###    echo "finished loading cnv data @ `date`"


bash $1/load_cnv.sh $3 ACC $1 $2
bash $1/load_cnv.sh $3 CHOL $1 $2
bash $1/load_cnv.sh $3 DLBC $1 $2
# bash $1/load_cnv.sh $3 UCS $1 $2

echo "start clinical data loading @ `date`"
for tumor_type in `cat tumor_type.tsv`; do
  bash $1/load_clinical_ming.sh $3 $tumor_type $1
done
echo "finished loading clinical data @ `date`"


echo "start RNA seq loading @: `date`"
  for tumor_type in `cat tumor_type.tsv`; do
    bash $1/load_RNAseqV2_v2.sh ${DATE} $tumor_type ${current_wd} ${gene_file}
  done
echo "finished RNA seq loading @: `date`"

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

echo "start methylation loading @: `date`"
  for tumor_type in `cat tumor_type.tsv`; do
    bash $1/load_methylation.sh $3 $tumor_type $1
  done
echo "finished methylation loading @: `date`"


## echo "start loading methylation data @ `date`"
## bash $1/load_methylation.sh $3 ACC $1
## bash $1/load_methylation.sh $3 BLCA $1
## bash $1/load_methylation.sh $3 BRCA $1
## bash $1/load_methylation.sh $3 CESC $1
## bash $1/load_methylation.sh $3 CHOL $1
## bash $1/load_methylation.sh $3 COAD $1
## bash $1/load_methylation.sh $3 COADREAD $1
## bash $1/load_methylation.sh $3 GBM $1
## bash $1/load_methylation.sh $3 GBMLGG $1 
## bash $1/load_methylation.sh $3 HNSC $1
## bash $1/load_methylation.sh $3 KICH $1
## bash $1/load_methylation.sh $3 KIPAN $1
## bash $1/load_methylation.sh $3 KIRC $1
## bash $1/load_methylation.sh $3 KIRP $1
## bash $1/load_methylation.sh $3 LAML $1
## bash $1/load_methylation.sh $3 LGG $1
## bash $1/load_methylation.sh $3 LIHC $1
## bash $1/load_methylation.sh $3 LUAD $1
## bash $1/load_methylation.sh $3 LUSC $1
## bash $1/load_methylation.sh $3 OV $1
## bash $1/load_methylation.sh $3 PAAD $1
## bash $1/load_methylation.sh $3 PCPG $1
## bash $1/load_methylation.sh $3 PRAD $1
## bash $1/load_methylation.sh $3 READ $1
## bash $1/load_methylation.sh $3 SARC $1
## bash $1/load_methylation.sh $3 SKCM $1
## bash $1/load_methylation.sh $3 STAD $1
## bash $1/load_methylation.sh $3 THCA $1 
## bash $1/load_methylation.sh $3 UCEC $1
## bash $1/load_methylation.sh $3 UCS $1
## bash $1/load_methylation.sh $3 UVM $1
## echo "finished loading methylation data @`date`"


