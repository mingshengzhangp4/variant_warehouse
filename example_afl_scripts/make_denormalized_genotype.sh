#!/bin/bash

##This rolls up per-variant data into the genotypes, making a denormalized schema.
#Takes a while but scales perfectly
iquery -anq "remove(KG_GENOTYPE_DENORMALIZED)" > /dev/null 2>&1

time iquery -naq "
store(
 project(
  apply(
   cross_join(
    KG_GENOTYPE as GT,
    project(
     KG_VARIANT,
     reference,
     alternate
    ) as VAR,
    GT.chromosome_id,
    VAR.chromosome_id,
    GT.start,
    VAR.start,
    GT.end,
    VAR.end,
    GT.alternate_id,
    VAR.alternate_id
   ),
   base_1, iif(allele_1, alternate, string(null)),
   base_2, iif(allele_2, alternate, string(null))
  ),
  reference,
  alternate,
  base_1,
  base_2
 ),
 KG_GENOTYPE_DENORMALIZED
)"

