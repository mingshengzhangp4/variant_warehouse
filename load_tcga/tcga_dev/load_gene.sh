#!/bin/bash

geneList_file=/home/mzhang/Paradigm4_labs/variant_warehouse/load_gene_37/newGene.tsv

if [ $# -ne 1 ]; then
    echo "need one arg: DATE, such as 2015_06_01"
    exit 1
fi


DATE=$1


## iquery -anq "remove(temp)"
iquery -anq "remove(TCGA_GENE_LOAD_BUF)"
iquery -anq "remove(TCGA_${DATE}_GENE_STD)"

iquery -anq "create array TCGA_${DATE}_GENE_STD
<gene_symbol: string null,
 entrez_geneID: uint64 null,
 start_: string null,
 end_: string null,
 strand_: string null,
 hgnc_synonym: string null,
 synonym: string null,
 dbXrefs: string null,
 cyto_band: string null,
 full_name: string null,
 type_of_gene: string null,
 chrom: string null,
 other_locations: string null>
[gene_id=0:*, 1000000,0]"


iquery -anq "create temp array TCGA_GENE_LOAD_BUF
<gene_symbol: string null,
 entrez_geneID: string null,
 start_: string null,
 end_: string null,
 strand_: string null,
 hgnc_synonym: string null,
 synonym: string null,
 dbXrefs: string null,
 cyto_band: string null,
 full_name: string null,
 type_of_gene: string null,
 chrom: string null,
 other_locations: string null,
 error: string null>
[source_instance_id=0:*,1,0,
 chunk_number=0:*,1,0,
 line_number=0:*,1000,0]"


## select yn in "yes" "no"; do
##     case $yn in
##         yes) break;;
##         no ) exit 1;;
##     esac
## done
 


iquery -anq "
store(
    parse(
        split('${geneList_file}', 'header=1','lines_per_chunk=1000'),
        'chunk_size=1000', 'num_attributes=13'
        ),
    TCGA_GENE_LOAD_BUF
    )"



## cast cannot go: null-able -> non null-able

iquery -anq "
store(
    redimension(
        cast(
            apply(
                unpack(TCGA_GENE_LOAD_BUF, z),
                gene_no,
                z 
                ),
            <source_instance_id: uint64,
             chunk_number: uint64,
             line_number: uint64,
             gene_symbol: string null,
             entrez_geneID: uint64 null,
             start_: string null,
             end_: string null,
             strand_: string null,
             hgnc_synonym: string null,
             synonym: string null,
             dbXrefs: string null,
             cyto_band: string null,
             full_name: string null,
             type_of_gene: string null,
             chrom: string null,
             other_locations: string null,
             error: string null,
             gene_no: uint64>
            [gene_id=0:*,1000000,0]
            ),
        TCGA_${DATE}_GENE_STD
        ),
    TCGA_${DATE}_GENE_STD
    )"
     
        
iquery -anq "remove(TCGA_GENE_LOAD_BUF)"
