#!/bin/bash

#Same as exact_join.sh but with some extra pre-filtering for example
#Note: 1000G and ESP use different units.
MIN_AF="0.2"
MIN_EA_MAF="40"
CHROMOSOME=10

time iquery -otsv -aq "
project(
 apply(
  filter(
   cross_join(
    filter(
     between(
       KG_VARIANT,
       $((CHROMOSOME-1)), null, null, null, $((CHROMOSOME-1)), null, null, null
     ),
     af > $MIN_AF
    ) as A,
    project(
     filter(
      between(ESP_VARIANT, $((CHROMOSOME-1)), null, null, null, $((CHROMOSOME-1)), null, null, null), 
      ea_maf > $MIN_EA_MAF
     ),
     reference, alternate, ea_maf
    ) as B,
    A.chromosome_id, B.chromosome_id,
    A.start, B.start,
    A.end,   B.end
   ),
   A.reference=B.reference and A.alternate=B.alternate
  ),
  pos, A.start
 ),
 pos, A.reference, A.alternate, A.af, B.ea_maf
)"
