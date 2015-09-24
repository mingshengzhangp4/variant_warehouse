#!/bin/bash

#  ./recreate_db_ming.sh

##  for tumor_type in `cat tumor_type.tsv`; do
##    ./load_clinical.sh 2015_06_01 $tumor_type
##  done



bash ./load_mutation_ming.sh 2015_06_01 ACC 39 40

  echo "completed one tumor type..."
  select yn in "yes" "no"; do
      case $yn in
          yes) break;;
          no ) exit 1 ;;
      esac
  done


./load_mutation_ming.sh 2015_06_01 BLCA 40 42
./load_mutation_ming.sh 2015_06_01 BRCA 49 50
./load_mutation_ming.sh 2015_06_01 CESC 49 50
./load_mutation_ming.sh 2015_06_01 CHOL 39 40
./load_mutation_ming.sh 2015_06_01 COAD 35 36
./load_mutation_ming.sh 2015_06_01 COADREAD 35 36
./load_mutation_ming.sh 2015_06_01 GBM 40 42
./load_mutation_ming.sh 2015_06_01 GBMLGG 40 42
./load_mutation_ming.sh 2015_06_01 HNSC 40 42
./load_mutation_ming.sh 2015_06_01 KICH 40 42
./load_mutation_ming.sh 2015_06_01 KIPAN 39 40
./load_mutation_ming.sh 2015_06_01 KIRC 39 40
./load_mutation_ming.sh 2015_06_01 KIRP 39 40
./load_mutation_ming.sh 2015_06_01 LAML 49 50
./load_mutation_ming.sh 2015_06_01 LGG 49 50
./load_mutation_ming.sh 2015_06_01 LIHC 39 40
./load_mutation_ming.sh 2015_06_01 LUAD 40 42
./load_mutation_ming.sh 2015_06_01 LUSC 40 42
./load_mutation_ming.sh 2015_06_01 OV 40 42
./load_mutation_ming.sh 2015_06_01 PAAD 40 42
./load_mutation_ming.sh 2015_06_01 PCPG 40 42
./load_mutation_ming.sh 2015_06_01 PRAD 40 42
./load_mutation_ming.sh 2015_06_01 READ 35 36
./load_mutation_ming.sh 2015_06_01 SARC 49 50
./load_mutation_ming.sh 2015_06_01 SKCM 40 42
./load_mutation_ming.sh 2015_06_01 STAD 40 42
./load_mutation_ming.sh 2015_06_01 THCA 40 42
./load_mutation_ming.sh 2015_06_01 UCEC 100 38
./load_mutation_ming.sh 2015_06_01 UCS 40 42
./load_mutation_ming.sh 2015_06_01 UVM 40 42
