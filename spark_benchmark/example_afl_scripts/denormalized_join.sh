#!/bin/bash

#This requires only

time iquery -aq "
op_count(   
 filter(
  cross_join(
    between(
     filter(
      KG_GENOTYPE_DENORMALIZED_2,
      a_1 is not null or a_2 is not null
     ),
     7, null,null,null,null, 7,null,null,null,null
    ) as A,
   project( 
    between(ESP_VARIANT, 7, null, null,null, 7,null,null,null),
    ref, alt
   ) as B,
   A.chromosome_id, 
   B.chromosome_id,
   A.start,
   B.start,
   A.end,
   B.end
  ),
  ((a_1 = alt or a_2 = alt) and reference = ref)
 )
)"
