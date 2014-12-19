#!/bin/bash

iquery --ignore-errors -aq "
remove(GVCF_DATA);
remove(GVCF_CHROMOSOME);
remove(GVCF_SAMPLE);

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
  sample_id     =0:*,100,0,
  start         =0:*,10000000,0,
  end           =0:*,10000000,0
];

create array GVCF_CHROMOSOME
<	chromosome :string >
[
	chromosome_id =0:*,1,0 
];

create array GVCF_SAMPLE
< sample :string >
[
  sample_id =0:*,100,0
];"

