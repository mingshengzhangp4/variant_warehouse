#!/bin/bash

#Very simple script to load sample-population mappings. This data is so small that the schema choices don't matter too much
MYDIR=`dirname $0`
pushd $MYDIR
MYDIR=`pwd`
FILE=$MYDIR/populations.tsv
if [ ! -f $FILE ] ; then
 echo "$FILE does not exist. KTHXBYE."
 exit 1
fi
NUM_SAMPLES=`iquery -otsv -aq "op_count(KG_SAMPLE)" | tail -n 1`
if [ -z $NUM_SAMPLES -o $NUM_SAMPLES -ne 2504 ] ; then
 echo "Didn't find the expected 2504 samples. KTHXBYE."
 exit 1;
fi
iquery -anq "remove(KG_POPULATION)" > /dev/null 2>&1
iquery -anq "remove(KG_SAMPLE_LOAD_BUF)" > /dev/null 2>&1
iquery -anq "create temp array KG_SAMPLE_LOAD_BUF <sample:string, population:string> [i]" > /dev/null 2>&1
iquery -anq "load(KG_SAMPLE_LOAD_BUF, '/home/bio/github/vcf_tools/kg_loader/populations.tsv',0, 'tsv')" > /dev/null 2>&1
iquery -anq "
store(
 redimension(
  index_lookup(
   index_lookup(
    between(KG_SAMPLE_LOAD_BUF, 1,null) as A,
    uniq(sort(project(between(KG_SAMPLE_LOAD_BUF, 1, null), population))),
    A.population,
    population_id
   ),
   KG_SAMPLE,
   A.sample,
   sample_id
  ),
  <population:string> [sample_id, population_id=0:4,5,0]
 ),
 KG_POPULATION
)"
