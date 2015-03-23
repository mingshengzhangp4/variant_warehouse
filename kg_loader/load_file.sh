#!/bin/bash

#Blow the world away and create a clean slate
#See also the comment at the top of load_file.sh
iquery --ignore-errors -aq "
remove(KG_SAMPLE);
remove(KG_VARIANT);
remove(KG_GENOTYPE);
remove(KG_CHROMOSOME);

create array KG_CHROMOSOME
<chromosome: string not null>
[chromosome_id];

create array KG_SAMPLE
<sample :string not null>
[sample_id];

create array KG_VARIANT
<
 reference :string not null,
 alternate :string not null,
 id        :string null,
 qual      :double null,
 filter    :string null,
 info      :string null,
 ac        :double null,
 af        :double null
>
[
 chromosome_id     =0:*,1,0,
 start             =0:*,10000000,0,       --a variant occurs roughly once in 300bp; this gives us ~30K variants per chunk 
 end               =0:*,10000000,0,       --many of the variants have large strings in the info fields
 alternate_id      =0:19,20,0             --arbitrary: up to 20 alternates with the same start and end position
];

create array KG_GENOTYPE             
<
 allele_1: bool null,
 allele_2: bool null,
 phase:    bool null
>
[
 chromosome_id     =0:*,1,0,
 start             =0:*,10000000,0,
 end               =0:*,10000000,0,
 alternate_id      =0:19,20,0,
 sample_id         =0:*,100,0              --gives us about 3M genotype/variant combinations per chunk
];"
