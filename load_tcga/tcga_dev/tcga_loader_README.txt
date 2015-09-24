********************************************************************
********************************************************************

RNAseqv2

*********************************************************************
*********************************************************************

** URL **

## wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.2015060100.0.0.tar.gz


** platform + algorithm/method **

Illumnia HiSeq
RSEM (V2)


** on exon or gene level **

gene 

** file structure in tar.gz **
illumina HiSeqNIFEST.txt
BRCA.rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.data.txt

** Content **

Hybridization REF       TCGA-3C-AAAU-01A-11R-A41B-07    TCGA-3C-AALI-01A-11R-A41B-07  ...
gene_id                 normalized_count                normalized_count              ...
?|100130426             0.0000                           0.0000                       ...
ADAMTS14|140766         75.4803                          123.9804                     ...
...........


**  scidb arrays **

update/insert: TCGA_{DATE}_SAMPLE_STD
update/insert: TCGA_{GATE}_GENE_STD
generate new array: TCGA_{DATE}_RNAseqV2_STD
    <RNAexpression_levl:string null>[sample_id=0:*, 1000000, 0, gene_id=0:*,10000,0]

entrez_geneID will be used for dimension gene_id. So we need to create an array with schema-

<entrezID:uint64, hgnc_symbol:string null, ....>
[geneIndex=0:*, 1000000, 0]






