#!/bin/bash

SAMPLE="HG00103"
#EGFR
CHROMOSOME=7
REGION_START=55086678
REGION_END=55279262

iquery -aq "
cross_join(
 cross_join(
  between(GVCF_DATA, null, null, null, $REGION_START, null, null, $REGION_END, null),
  filter(GVCF_CHROMOSOME, chromosome='$CHROMOSOME'),
  GVCF_DATA.chromosome_id,
  GVCF_CHROMOSOME.chromosome_id
 ),
 filter(GVCF_SAMPLE, sample='$SAMPLE'),
 GVCF_DATA.sample_id,
 GVCF_SAMPLE.sample_id
)"
