#!/bin/bash

iquery --ignore-errors -aq "
remove(GVCF_DATA);
remove(GVCF_CHROMOSOME);
remove(GVCF_SAMPLE);

create array GVCF_SAMPLE
< sample:string >
[sample_id];

create array GVCF_CHROMOSOME
< chromosome:string not null> 
[chromosome_id];

store(build(GVCF_CHROMOSOME, '[(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(X),(Y),(MT)]', true), GVCF_CHROMOSOME);

create array GVCF_DATA
<
  ref : string null,
  alts : string null,
  info :string null,
  gt :string null,
  dp :int64 null,
  ad :string null,
  pl :string null,
  count: uint64 null
>
[
  chromosome_id =0:*,1,0, 
  sample_id     =0:*,50,0,
  start         =0:*,10000000,0,
  end           =0:*,10000000,0
];"

