#!/bin/bash

#See also comment at the top of load_file.sh
#Blow the world away and create a clean slate
iquery --ignore-errors -aq "
remove(KG_SAMPLE);
remove(KG_VARIANT);
remove(KG_GENOTYPE);
remove(KG_CHROMOSOME);

create array KG_SAMPLE
< sample :string >
[ sample_id ];               --system will pick chunk size of 1M by default

create array KG_CHROMOSOME
< chromosome: string >
[ chromosome_id ];

create array KG_VARIANT
<reference:string,
 alternate:string,
 id:string NULL DEFAULT null,
 qual:double NULL DEFAULT null,
 filter:string NULL DEFAULT null,
 info:string NULL DEFAULT null,
 ac:double NULL DEFAULT null,
 af:double NULL DEFAULT null> 
[chromosome_id=0:*,1,0,
 start        =0:*,10000000,0,  --gives us about 30K variants per chunk; many INFO fields contain long strings
 end          =0:*,10000000,0,
 alternate_id =0:19,20,0];

create array KG_GENOTYPE
<allele_1:bool NULL DEFAULT null,
 allele_2:bool NULL DEFAULT null,
 phase:bool NULL DEFAULT null> 
[chromosome_id=0:*,1,0,
 start        =0:*,10000000,0,
 end          =0:*,10000000,0,
 alternate_id =0:19,20,0,
 sample_id    =0:*,100,0];     --about 3M variant/sample entries per chunk, using small boolean attributes
"
