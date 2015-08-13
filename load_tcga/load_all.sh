#!/bin/bash

./recreate_db.sh

for tumor_type in `cat tumor_type.tsv`; do
  ./load_clinical.sh 2015_06_01 $tumor_type
done
