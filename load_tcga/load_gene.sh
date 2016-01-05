#!/bin/bash

#  geneList_file=/home/mzhang/Paradigm4_labs/variant_warehouse/load_tcga/gene_symbol_as_id.tsv

if [ $# -ne 2 ]; then
    echo "need two args:"
    echo "1. DATE, such as 2015_06_01"
    echo "2. geneList_file, such as-"
    echo "/home/mzhang/Paradigm4_labs/variant_warehouse/load_tcga/gene_symbol_as_id.tsv"
    exit 1
fi


DATE=$1
geneList_file=$2

iquery -anq "remove(TCGA_GENE_LOAD_BUF)"

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


iquery -anq "
store(
    parse(
        split('${geneList_file}', 'header=1','lines_per_chunk=1000'),
        'chunk_size=1000', 'num_attributes=13'
        ),
    TCGA_GENE_LOAD_BUF
    )"


iquery -anq "
store(
    redimension(
        cast(
            apply(
                unpack(TCGA_GENE_LOAD_BUF, z),
                gene_no,
                z 
                ),
            <source_instance_id: int64,
             chunk_number: int64,
             line_number: int64,
             gene_symbol: string null,
             entrez_geneID: int64 null,
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
             gene_no: int64>
            [gene_id=0:*,1000000,0]
            ),
        TCGA_${DATE}_GENE_STD
        ),
    TCGA_${DATE}_GENE_STD
    )"
     
       
iquery -anq "remove(TCGA_GENE_LOAD_BUF)"
