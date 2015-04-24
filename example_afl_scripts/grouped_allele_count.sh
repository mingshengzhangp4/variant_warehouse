#!/bin/bash

#Example low-level SciDB query script:
#Given a chromosome, start and end coordinates,
#Select all variants and genotypes that overlap the range from 1000 Genomes
#Join with major population data,
#Compute allele count, grouped by variant and populaiton;
#Export the result in a specified location as TSV

#Need to load 1000G variants (at least the example file) and populations first

#Gene DIP2C
CHROMOSOME=10
START=320130
END=735621

OUTPUT_PATH='/tmp/grouped_allele_count.tsv'

time iquery -anq "
--AFL comments start with --
save(
 project(
  --unpack flattens the structure for nicer-looking output
  unpack(
   --cross_joins work best when the larger array is the first argument. Here we have two nested joins
   cross_join(
    aggregate(
     cross_join(
      --the between is what performs ultra-fast range selections taking advantage of SciDB's clustering 
      between(
       apply(
        KG_GENOTYPE, 
        ac, iif(allele_1, 1, 0) +  iif(allele_2, 1, 0)
       ),
       --give me all ranges R where R.end <= START and R.start <= END (overlaps) on this chromosome
       $((CHROMOSOME-1)), null, $START, null, null,
       $((CHROMOSOME-1)), $END, null,   null, null
      ) as A,
      KG_POPULATION as B,
      A.sample_id,
      B.sample_id
     ),
     sum(ac) as ac,
     --the max is superfluous, we just want the population string for output
     max(population) as population,
     --group by these dimensions
     chromosome_id, start, end, alternate_id, population_id
    ) as C,
    project(
     between(
      KG_VARIANT,
       $((CHROMOSOME-1)), null, $START, null,
       $((CHROMOSOME-1)), $END, null,   null
     ),
     reference, 
     alternate
    ) as D,
    --join on these dimensions
    C.chromosome_id, D.chromosome_id,
    C.start, D.start,
    C.end, D.end,
    C.alternate_id, D.alternate_id
   ),
   j
  ),
  start,
  reference,
  alternate,
  population,
  ac
 ),
 '$OUTPUT_PATH', 0, 'tsv'
)"

