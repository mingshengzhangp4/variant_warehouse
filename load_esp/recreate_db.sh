#!/bin/bash

#See also comment at the top of load_file.sh
#Blow the world away and create a clean slate
iquery --ignore-errors -anq "
remove(ESP_VARIANT);
remove(ESP_CHROMOSOME);

create array ESP_CHROMOSOME
< chromosome:string not null>
[ chromosome_id ];

store(build(ESP_CHROMOSOME, '[(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(X),(Y),(MT)]', true), ESP_CHROMOSOME);

create array ESP_VARIANT
<reference:string not null,
 alternate:string not null,
 id:string            null,
 qual:double          null,
 filter:string        null,
 info:string          null,
 ea_maf: double       null,
 aa_maf: double       null>
[chromosome_id=0:*,1,0,
 start        =0:*,10000000,0,
 end          =0:*,10000000,0,
 alternate_id =0:19,20,0];
"

