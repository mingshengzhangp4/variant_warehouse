#!/bin/bash

#Very simple script to load GRCh37 gene locations
MYDIR=`dirname $0`
pushd $MYDIR
MYDIR=`pwd`
FILE=$MYDIR/genes.tsv
if [ ! -f $FILE ] ; then
 echo "$FILE does not exist. KTHXBYE."
 exit 1
fi
iquery -anq "remove(GENE_37)" > /dev/null 2>&1
set -e
iquery -anq "create array GENE_37 <gene:string, chromosome:string, start:int64, end:int64> [i]" > /dev/null 2>&1
iquery -anq "load(GENE_37, '$FILE', 0, 'tsv')" > /dev/null 2>&1
iquery -otsv -aq "aggregate(GENE_37, count(*) as num_loaded_genes)"
