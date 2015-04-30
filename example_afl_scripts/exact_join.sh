#!/bin/bash

#Count how many variants are in both 1000G and ESP
#Pick one chromosome using a fast filtereing with between. Not necessary.
CHROMOSOME=10
time iquery -aq "
op_count(
 filter(
  cross_join(
   project(
    between(
     KG_VARIANT,
     $((CHROMOSOME-1)), null, null, null, $((CHROMOSOME-1)), null, null, null
    ), 
    reference, alternate
   ) as A,
   project(
    between(ESP_VARIANT, $((CHROMOSOME-1)), null, null, null, $((CHROMOSOME-1)), null, null, null), 
    reference, alternate
   ) as B,
   A.chromosome_id, B.chromosome_id,
   A.start, B.start,
   A.end,   B.end
  ),
  (A.alternate=B.alternate and A.reference=B.reference)
 )
)"
