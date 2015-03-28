#!/bin/bash

#See also comment at the top of load_file.sh
#Blow the world away and create a clean slate
iquery --ignore-errors -anq "
remove(KG_SAMPLE);
remove(KG_VARIANT);
remove(KG_GENOTYPE);
remove(KG_CHROMOSOME);

create array KG_SAMPLE
< sample :string not null>
[ sample_id ];               --system will pick chunk size of 1M by default

create array KG_CHROMOSOME
< chromosome: string not null>
[ chromosome_id ];

store(build(KG_CHROMOSOME, '[(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(X),(Y),(MT)]', true), KG_CHROMOSOME);

create array KG_VARIANT
<reference:string not null,
 alternate:string not null,
 id:string            null,
 qual:double          null,
 filter:string        null,
 info:string          null,
 ac:double            null,
 af:double            null> 
[chromosome_id=0:*,1,0,
 start        =0:*,10000000,0,  --gives us about 30K variants per chunk; many INFO fields contain long strings
 end          =0:*,10000000,0,
 alternate_id =0:19,20,0];

create array KG_GENOTYPE
<allele_1:bool        null,
 allele_2:bool        null,
 phase:bool           null> 
[chromosome_id=0:*,1,0,
 start        =0:*,10000000,0,
 end          =0:*,10000000,0,
 alternate_id =0:19,20,0,
 sample_id    =0:*,100,0];     --about 3M variant/sample entries per chunk, using small boolean attributes
"
