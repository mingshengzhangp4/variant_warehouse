

********************************************************************
********************************************************************

GENE Array (base)

*********************************************************************
*********************************************************************

** data URL **

  https://github.com/Paradigm4/variant_warehouse/load_gene_37/newGene.tsv
  
  -- python for generating this file --
  https://github.com/Paradigm4/variant_warehouse/load_gene_37/
        tcga_python_pipe/create_gene_attributes.py

** Data layout (newGene.tsv) **

hgnc_symbol	entrez_geneID	Start	End	Strand	hgnc_synonym	ncbi_synonym	dbXrefs	cyto_band	full_name	Type_of_gene	chromosome	other_locations

A1BG	1	58858172	58864865	-	_	A1B|ABG|GAB|HYST2477	MIM:138670|HGNC:HGNC:5|Ensembl:ENSG00000121410|HPRD:00726|Vega:OTTHUMG00000183507	19q13.4	alpha-1-B glycoprotein	protein-coding	19	_
A2M	2	9220304	9268558	-	FWP007, S863-7, CPAMD5	A2MD|CPAMD5|FWP007|S863-7	MIM:103950|HGNC:HGNC:7|Ensembl:ENSG00000175899|HPRD:00072|Vega:OTTHUMG00000150267	12p13.31	alpha-2-macroglobulin	protein-coding	12	_


** scidb gene array schema **

TCGA_2015_06_01_GENE_STD
<gene_symbol:string NULL, entrez_geneID:int64 NULL,start_:string NULL,end_:string NULL,strand_:string NULL,hgnc_synonym:string NULL,synonym:string NULL,dbXrefs:string NULL,cyto_band:string NULL,full_name:string NULL,type_of_gene:string NULL,chrom:string NULL,other_locations:string NULL>
 [gene_id=0:*,1000000,0]'

** scripts for creating the array **

https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/load_gene.sh




********************************************************************
********************************************************************

RNAseqv2 array

*********************************************************************
*********************************************************************

** data URL **

## wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.2015060100.0.0.tar.gz


** platform + algorithm/method **

Illumnia HiSeq
RSEM (V2)


** on exon or gene level **

gene 

** file structure in tar.gz **
illumina HiSeqMANIFEST.txt
BRCA.rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.data.txt

** Content **

Hybridization REF       TCGA-3C-AAAU-01A-11R-A41B-07    TCGA-3C-AALI-01A-11R-A41B-07  ...
gene_id                 normalized_count                normalized_count              ...
?|100130426             0.0000                           0.0000                       ...
ADAMTS14|140766         75.4803                          123.9804                     ...
...........


** scidb array schema **

TCGA_{DATE}_RNAseqV2_STD
    <RNA_expressionLevel:string null>
    [tumor_type_id:0:*,1,0,
     sample_id=0:*, 1000000, 0,
     gene_id=0:*,1000,0]

**  loading scripts **

https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/load_RNAseqV2.sh

include-
update/insert: TCGA_{DATE}_PATIENT_STD
update/insert: TCGA_{DATE}_SAMPLE_STD
update/insert: TCGA_{GATE}_GENE_STD

********************************************************************
********************************************************************

CLIN array

*********************************************************************
*********************************************************************

** data URL **

http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_Clinical.Level_1.${DATE_SHORT}00.0.0.tar.gz


** file structure in tar.gz **
MANIFEST.txt          BRCA.merged_only_biospecimen_clin_format.txt
BRCA.clin.merged.txt  BRCA.merged_only_clinical_clin_format.txt


** Content **

--all three files (BRCA.*.txt) merged--
  * BRCA.merged_only_biospecimen_clin_format.txt
    2190 rows, 1087 columns
  * BRCA.merged_only_clinical_clin_format.txt
    1496 rows, 1087 columns
  * BRCA.clin.merged.txt
    2190+1496 rows, 1087 columns

   note: 1087 columns = 1086 patient-columns + 1 clinical_type-column(column 0) 

--layout--
V1                           V2.x            V3.x            V4.x         ... V1085.x V1086.x
admin.batch_number           379.20.0        379.20.0        379.20.0     ...
    ..........
patient.bcr_patient_barcode  tcga-3c-aaau    tcga-3c-aali    tcga-3c-aalj ... 
    ..........

** scidb array schema **

TCGA_${DATE}_CLINICAL_STD 
<key:string,value:string null> 
[tumor_type_id=0:*,1,0,
 clinical_line_nbr=0:*,1000,0,
 patient_id=0:*,1000,0]

  note: clinical_line_nbr == row # <-> key == column 0
        so a TCGA_CLIN_KEY array is created to map key <-> clinical_line_nbr

** loading scripts **


https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/load_clinical_ming.sh

include-
update/insert: TCGA_{DATE}_PATIENT_STD (an intermediate patient list file created for this)

********************************************************************
********************************************************************

MUTATION array

*********************************************************************
*********************************************************************

** data URL **

http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Mutation_Packager_Calls.Level_3.${DATE_SHORT}00.0.0.tar.gz


** file structure in tar.gz **
MANIFEST.txt             TCGA-OR-A5LH-01.maf.txt  TCGA-OR-A5L2-01.maf.txt ...(all samples)


** Content of a maf file **

Hugo_Symbol	Entrez_Gene_Id	Center	   NCBI_Build	Chromosome	Start_position ...(67 fields)
AK2	        204	        bcgsc.ca	37	1	        334789831      ...

note: for some files, Entrez_Gene_ID is empty (e.g. BRCA all set to 0)

** scidb array schema **

 TCGA_${DATE}_MUTATION_STD
 <GRCh_release:string null,
  mutation_genomic_start:int64 null,
  mutation_genomic_end:int64 null,
  mutation_type: string null,
  variant_type: string null,  
  reference_allele:string null,
  tumor_allele:string null,
  c_pos_change:string null,
  p_pos_change:string null>
 [tumor_type_id=0:*,1,0,
  gene_id=0:*,1000000,0,
  sample_id=0:*,1000,0,
  mutation_id=0:*,100000,0]"

** loading scripts **


https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/load_mutation_ming.sh

include-
update/insert: TCGA_{DATE}_PATIENT_STD
update/insert: TCGA_{DATE}_SAMPLE_STD
update/insert: TCGA_{GATE}_GENE_STD


********************************************************************
********************************************************************

METHYLATION array

*********************************************************************
*********************************************************************

** data URL **

 wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.2015060100.0.0.tar.gz


** file structure in tar.gz **
MANIFEST.txt
ACC.methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.data.txt

** Content of data file **

column# == fields = 4 * sample# + 1
row# == records = 485579 = probe# + 2

line 0 ('|' inserted to group fields):
Hybridization REF |  TCGA-OR-A5J1-01A-11D-A29J-05    TCGA-OR-A5J1-01A-11D-A29J-05    TCGA-OR-A5J1-01A-11D-A29J-05    TCGA-OR-A5J1-01A-11D-A29J-05  |  TCGA-OR-A5J2-01A-11D-A29J-05    TCGA-OR-A5J2-01A-11D-A29J-05    TCGA-OR-A5J2-01A-11D-A29J-05   TCGA-OR-A5J2-01A-11D-A29J-05 | ...

line 1:
Composite Element REF |  Beta_value      Gene_Symbol     Chromosome      Genomic_Coordinate  |   Beta_value      Gene_Symbol     Chromosome      Genomic_Coordinate | ...

line 2:
cg00000029   |   0.119877013723081       RBL2    16      53468112   |    0.107120474727399       RBL2    16      53468112 | ... 

line 3:
cg00000108   |   NA      C3orf35     3    37459206  |     NA      C3orf35    3      37459206 | ...

...

line n:
cg02045224   |  0.0287637195761093 TP53;WRAP53  17  7591618 |  0.0176466187097269  TP53;WRAP53  17  7591618 | ...

....

line 485578: 
rs9839873   |    0.708642513847403       NA      NA    0   |    0.94338354578915        NA      NA      0  | ...     

  @@ NOTE @@
  each probe may correspond to 1 or more or 'NA' gene_symbols; entries with 'NA' gene_symbols are excluded


** scidb array schema **


TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD
<probe_name:string,
reference_chromosome:string,
genomic_start:int64,
genomic_end:int64,
reference_gene_symbols:string>
[gene_id=0:*,1000000,0,
humanmethylation450_probe_id=0:*,1000,0]

 @@ NOTE @@
  reference_gene_symbols could look like "TP53",  "TP53|WRAP53", but not "NA", which is discarded


 TCGA_${DATE}_HUMANMETHYLATION450_STD
 <value:int64 null>
 [tumor_type_id=0:*,1,0,
  sample_id=0:*,1000,0,
  humanmethylation450_probe_id=0:*,1000]"


** loading scripts **

1. input data preprossor (python parser)

https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/methylation_file_parser.py
  input:ACC.methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.data.txt
  outputs:
      (1) methyl_sample_barcodes.txt(\n separated ascii file)
          TCGA-OR-A5J1-01A-11D-A29J-05
          TCGA-OR-A5J2-01A-11D-A29J-05
          ...

      (2) methyl_genes.txt ('NA' excluded)

          RBL2
          TP53
          ...

      (3) methyl_probe_data.txt
          probe_name  gene_symbol  reference_chromosome genomic_start genomic_end reference_gene_symbols
           cg02045224   TP53               17              7591618        7591618     TP53;WRAP53  
           cg02045224   WRAP53             17              7591618        7591618     TP53;WRAP53
           cg00000029   RBL2               16              53468112       53468112      RBL2
           ...

      (4) methyl_data.txt
          cg00000108 0.78 0.21 ...
          cg00000029 0.99 0.32 ...
          ...


2. methylation data loader

https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/load_methylation.sh

include-
update/insert: TCGA_{DATE}_PATIENT_STD
update/insert: TCGA_{DATE}_SAMPLE_STD
update/insert: TCGA_{GATE}_GENE_STD


