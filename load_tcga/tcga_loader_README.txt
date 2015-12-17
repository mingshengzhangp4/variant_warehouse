tumor type info(ACC, BRCA,...):

gdac.broadinstitute.org/runs/stddata__2015_06_01/ingested_data.tsv


disease_name map:

gdac.broadinstitute.org/runs/info/tcga_disease_name_map.txt(ACC: Adrenocortical carcinoma, ...)
gdac.broadinstitute.org/runs/info/clinical(ACC ->[date_of_initial, days_to_death...], BLCA ->[])

Study Abbreviation	Study Name
ACC	Adrenocortical carcinoma
BLCA	Bladder Urothelial Carcinoma
BRCA	Breast invasive carcinoma
CESC	Cervical squamous cell carcinoma and endocervical adenocarcinoma
CHOL	Cholangiocarcinoma
COAD	Colon adenocarcinoma
COADREAD	Colorectal adenocarcinoma
DLBC	Lymphoid Neoplasm Diffuse Large B-cell Lymphoma
ESCA	Esophageal carcinoma 
FPPP	FFPE Pilot Phase II
GBM	Glioblastoma multiforme
GBMLGG	Glioma
HNSC	Head and Neck squamous cell carcinoma
KICH	Kidney Chromophobe
KIPAN	Pan-kidney cohort (KICH+KIRC+KIRP)
KIRC	Kidney renal clear cell carcinoma
KIRP	Kidney renal papillary cell carcinoma
LAML	Acute Myeloid Leukemia
LGG	Brain Lower Grade Glioma
LIHC	Liver hepatocellular carcinoma
LUAD	Lung adenocarcinoma
LUSC	Lung squamous cell carcinoma
MESO	Mesothelioma
OV	Ovarian serous cystadenocarcinoma
PAAD	Pancreatic adenocarcinoma
PANCAN12	PANCANCER cohort with 12 disease types
PANCAN18	PANCANCER cohort with 18 disease types
PANCAN8	PANCANCER cohort with 8 initial disease types
PANCANCER	Complete PANCANCER set
PCPG	Pheochromocytoma and Paraganglioma
PRAD	Prostate adenocarcinoma
READ	Rectum adenocarcinoma
SARC	Sarcoma
SKCM	Skin Cutaneous Melanoma
STAD	Stomach adenocarcinoma
STES	Stomach and Esophageal carcinoma
TGCT	Testicular Germ Cell Tumors
THCA	Thyroid carcinoma
THYM	Thymoma
UCEC	Uterine Corpus Endometrial Carcinoma
UCS	Uterine Carcinosarcoma
UVM	Uveal Melanoma



TCGA barcode

https://wiki.nci.nih.gov/display/TCGA/TCGA+barcode

Code Table report

https://tcga-data.nci.nih.gov/datareports/codeTablesReport.htm?codeTable=Sample%20type

01 Primary solid Tumor TP
02 Recurrent Solid Tumor TR
03 Primary Blood Derived Cancer - Peripheral Blood TB
04 Recurrent Blood Derived Cancer - Bone Marrow TRBM
05 Additional - New Primary TAP
06 Metastatic TM
07 Additional Metastatic TAM
08 Human Tumor Original Cells THOC
09 Primary Blood Derived Cancer - Bone Marrow TBM
10 Blood Derived Normal NB
11 Solid Tissue Normal NT
12 Buccal Cell Normal NBC
13 EBV Immortalized Normal NEBV
14 Bone Marrow Normal NBM
20 Control Analyte CELLC
40 Recurrent Blood Derived Cancer - Peripheral Blood TRB
50 Cell Lines CELL
60 Primary Xenograft Tissue XP
61 Cell Line Derived Xenograft Tissue XCL





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

** Data layout (newGene.tsv):  hgnc_symbol-entrez_geneID may be many-one **

hgnc_symbol	entrez_geneID	Start	End	Strand	hgnc_synonym	ncbi_synonym	dbXrefs	cyto_band	full_name	Type_of_gene	chromosome	other_locations

A1BG	1	58858172	58864865	-	_	A1B|ABG|GAB|HYST2477	MIM:138670|HGNC:HGNC:5|Ensembl:ENSG00000121410|HPRD:00726|Vega:OTTHUMG00000183507	19q13.4	alpha-1-B glycoprotein	protein-coding	19	_
A2M	2	9220304	9268558	-	FWP007, S863-7, CPAMD5	A2MD|CPAMD5|FWP007|S863-7	MIM:103950|HGNC:HGNC:7|Ensembl:ENSG00000175899|HPRD:00072|Vega:OTTHUMG00000150267	12p13.31	alpha-2-macroglobulin	protein-coding	12	_

** generate gene list with gene_symbol as unique gene id **

    --python script for generating this file --
    https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/gene_symbol_as_geneID.py
   
    --input file --
    https://github.com/Paradigm4/variant_warehouse/load_gene_37/newGene.tsv

    --output file: same format as input but hgnc_symbol-entrez_geneIDs is one-one (collapse entrezIDs) --
    https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/gene_symbol_as_id.tsv


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

== old versions, parsing normalized data ==
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
    
    ** python code to parse probe_id to canonical gene name **
        -- script --
          RNAseq_parser.py
    
        --input file --   
          BRCA.rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.data.txt
    
        --output file --
          RNAseq_data.tsv
           
          ** Content **
          
          Hybridization REF       TCGA-3C-AAAU-01A-11R-A41B-07    TCGA-3C-AALI-01A-11R-A41B-07  ...
          gene_id                 normalized_count                normalized_count              ...
          ABC                     0.0000                           0.0000                       ...
          ADAMTS14                75.4803                          123.9804                     ...
          ...........
    
    ** scidb array schema **
    TCGA_${DATE}_RNAseqV2_STD
    <RNA_expressionLevel:double null>
    [tumor_type_id=0:*,1,0,
     sample_id=0:*,1000,0,
     gene_id=0:*,1000000,0]"

   
        **  loading scripts **
    
    https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/load_RNAseqV2.sh + load_RNAseqV2_v2.sh
    
    include-
    update/insert: TCGA_{DATE}_PATIENT_STD
    update/insert: TCGA_{DATE}_SAMPLE_STD
    update/insert: TCGA_{GATE}_GENE_STD

== new versions, parsing raw_count + scaled_estimate  ==
    ** data URL **
    
    ## wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes__data.Level_3.2015060100.0.0.tar.gz
    
    
    ** platform + algorithm/method **
    
    Illumnia HiSeq
    RSEM (V2)
    
    
    ** on exon or gene level **
    
    gene 
    
    ** file structure in tar.gz **
    illumina HiSeqMANIFEST.txt
    BRCA.rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes__data.data.txt
    
    ** Content **
    
    Hybridization REF       TCGA-3C-AAAU-01A-11R-A41B-07    TCGA-3C-AALI-01A-11R-A41B-07  ...

    gene_id    raw_count       scaled_estimate         transcript_id      raw_count       scaled_estimate transcript_id
   ?|100130426     0.00          0                        uc011lsn.1         0.00                0       uc011lsn.1 
A2BP1|54715     36.00   2.52115894577257e-07    uc002cyr.1,uc002cys.2,..    14.00   1.03297569200245e-07 uc002cyr.1,uc002cys.2,.. 
    ........

    
    ** python code to parse probe_id to canonical gene name **
        -- script --
          RNAseq_parser_raw.py
    
        --input file --   
          BRCA.rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes__data.data.txt
    
        --output file 1--
          RNAseq_data_raw_count.tsv
           
          ** Content **
          
          Hybridization REF       TCGA-3C-AAAU-01A-11R-A41B-07    TCGA-3C-AALI-01A-11R-A41B-07  ...
          gene_id                 raw_count                       raw_count                     ...
          ABC                     0.0000                           0.0000                       ...
          ADAMTS14                75.4803                          123.9804                     ...
          ...........
 
        --output file 2--
          RNAseq_data_scaled_estimate.tsv
           
          ** Content **
          
          Hybridization REF       TCGA-3C-AAAU-01A-11R-A41B-07    TCGA-3C-AALI-01A-11R-A41B-07  ...
          gene_id                 scaled_estimate                  scaled_estimate              ...
          ABC                     0.0000                           0.0000                       ...
          ADAMTS14                0.34                             0.804                        ...
          ...........

    ** scidb array schema **
    
        TCGA_{DATE}_RNAseq_STD
        <raw_count:double null,
         scaled_estimate:double null>
        [tumor_type_id:0:*,1,0,
         sample_id=0:*, 1000, 0,
         gene_id=0:*,10000000,0]
    
    **  loading scripts **
    
    https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/load_RNAseq_raw.sh
    
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


********************************************************************
********************************************************************

CNV array

*********************************************************************
*********************************************************************

** data URL **

wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.Level_3.2015060100.0.0.tar.gz


** file structure in tar.gz **
MANIFEST.txt
ACC.snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.seg.txt


** Content of data file **

          Sample            Chromosome	Start	   End	     Num_Probes	  Segment_Mean
TCGA-OR-A5J1-10A-01D-A29K-01	1	3218610	  247813706	128989	1e-04
TCGA-OR-A5J1-10A-01D-A29K-01	2	484222	   45753961	26796	0.0073
TCGA-OR-A5J1-10A-01D-A29K-01	2	45759027   45759054	2	-1.6119
TCGA-OR-A5J1-10A-01D-A29K-01	2	45764419   167211490	61083	0.0067
    ... (21053 rows)

** scidb array schema **


TCGA_${DATE}_GENOME_WIDE_SNP_6_PROBE_STD
<probe_name:string,
reference_chromosome:string,
genomic_start:int64,
genomic_end:int64,
reference_gene_symbols:string>
[gene_id=0:*,1000000,0,
genome_wide_snp_6_probe_id=0:*,1000,0]

TCGA_${DATE}_GENOME_WIDE_SNP_6_STD
<value:double null>
[tumor_type_id=0:*,1,0,
 sample_id=0:*,1000,0,
 genome_wide_snp_6_probe_id=0:*,1000]"


 @@ NOTE @@
  probe_name = gene_symbols + [ |_MAX|_MIN]

iquery -aq "cross_join(TCGA_2014_06_14_GENOME_WIDE_SNP_6_STD as A, TCGA_2014_06_14_GENOME_WIDE_SNP_6_PROBE_STD as B, A.genome_wide_snp_6_probe_id, B.genome_wide_snp_6_probe_id)" | less

{tumor_type_id,sample_id,genome_wide_snp_6_probe_id,gene_id} value,probe_name,reference_chromosome,genomic_start,genomic_end,reference_gene_symbols
{0,0,3,2293} 0.2555,'"MIR3118-5"','',0,0,'|"MIR3118-5"|'
{0,0,4,2304} -0.7854,'"MIR3118-6"','',0,0,'|"MIR3118-6"|'
{0,0,5,6731} 0.1965,'"RNVU1-1"','',0,0,'|"RNVU1-1"|'
{0,0,6,7968} 0.5576,'"RNVU1-9"','',0,0,'|"RNVU1-9"|'
{0,0,7,5844} -0.3466,'3.8-1.3','',0,0,'|3.8-1.3|'
{0,0,331,3120} 0.2348,'ABHD17B','',0,0,'|ABHD17B|'
{0,0,334,3095} -0.2658,'ABHD17C','',0,0,'|ABHD17C|'
{0,0,409,97} -0.2553,'ACAA1','',0,0,'|ACAA1|'
{0,0,412,46} -0.226,'ACAA2','',0,0,'|ACAA2|'
{0,0,416,139} 0.5517,'ACACA_MAX','',0,0,'|ACACA|'
{0,0,417,139} 0.1796,'ACACA_MIN','',0,0,'|ACACA|'
{0,0,418,146} 0.5675,'ACACB','',0,0,'|ACACB|'
{0,0,421,182} 0.5675,'ACAD10','',0,0,'|ACAD10|'
{0,0,424,178} -0.2458,'ACAD11','',0,0,'|ACAD11|'

** loading scripts **

1. input data preprossor (python parser: binary search on sorted list of [left_coord, gene_symbol])

https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/cnv_file_parser.py
  input:ACC.snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.seg.txt
  outputs:
      (1) cnv_sample_barcodes.txt(\n separated ascii file)
          TCGA-OR-A5J1-01A-11D-A29J-05
          TCGA-OR-A5J2-01A-11D-A29J-05
          ...

      (2) cnv_probe_data.txt
          probe_name    gene_symbol    Chromosome	  Start	            End	
            'ACAA1'   '|ACAA1|'     	2	          484222	   45753961
          'ACACA_MAX' '|ACACA|'        	2	          484222	   45753961
          'ACACA_MIN' '|ACACA|'         2	          484222	   45753961
                ...
          '"RNVU1-1"' '"RNVU1-1"'       17                435566           12345678
                ...

      (4) cnv_data.txt
                     sample_barcode       probe_name     value
          TCGA-OR-A5J1-10A-01D-A29K-01     'ACAA1'       -0.226 
          TCGA-OR-A5J1-10A-01D-A29K-01   'ACACA_MAX'     0.5517
          TCGA-OR-A5J1-10A-01D-A29K-01   'ACACA_MIN'     0.1796
          TCGA-OR-A5J1-10A-01D-A29K-01   '"RNVU1-1"'     0.5675



2. cnv data loader

https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/load_cnv.sh

include-
update/insert: TCGA_{DATE}_PATIENT_STD
update/insert: TCGA_{DATE}_SAMPLE_STD

3. algorithm

  (1)  sample  --> chrom:segment_coordinate_value
  (2)*  chrom:segment_coordinates --> mapped gene_list
  (3) --> {sample1:[(gene_symbol1,[val1.0, val1.1,...]), (gene_symbol2, [val2.0, val2.1, ...]), ...],
        sample2:[(gene_symbol1,[val1.0, val1.1,...]), (gene_symbol2, [val2.0, val2.1, ...]), ...],
        ...
       }
  (4) --> 
       gene_symbol -> probe_name: one-many
       sample:probe_name -> value:  one-one
       if len([valx.0, valx.1,...]) == 1,
          proble_name = gene_symbol
          val = vals
       else: # multiple vals
          probe_name = gene_symbol_MAX, val = max(vals)
          probe_name = gene_symbol_MIN, val = max(vals)

       sample1, probe_name1, val1,
       sample1, probe_name2, val2,
       ....
       sample2, probe_name1, val,
       sample2, probe_name2, val
       ....

  *(2) involves steps:
      a) create gene list from gene list file (technically, tuple of list of tuple)
           -> (
                [(gene1.1, start_, end_), (gene1.2, start_, end_), ...],
                [(gene2.1, start_, end_), (gene2.2, start_, end_), ...],
                     ......
                [(gene23.1, start_, end_), (gene23.2, start_, end_), ...], # X-chrom
                [gene24.1, start_, end_), (gene24.2, start_, end_), ...],  # Y-chrom
                [gene25.1, start_, end_),(gene25.2, start_, end_), ...]    # MT-chrom
              )
               
      b) sorting the gene list by start_ of each chromosome
      c) for each sample:chrom:segment_coordinates, binary search the above sorted list and find all genes fall into this segment.
          i) start with the seg_left position; the target gene is noted 't_left'
          ii) target window (one_side of window boundaries is moved at a time)
              - starting window [gene_0, gene_(n-1)]
              - checking boundary conditions
                  if seg_left < gene_0
                      t_left = gene_0
                  else if seg_left > gene_(n-1)
                      t-left = null
                  else:
                      starting iteration below
              - general window [gene_i, gene_j]
              - if seg_left in gene_i
                    t_left = gene_i
                else if seg_left in gene_(i+1)
                    t_left = gene_(i+1)
                else if seg_left < gene_(i+1)
                    t_left = gene_(i+1)
                else if seg_left in gene_j
                    t_left = gene_j
                else if seg_left in gene_(j-1)
                    t_left = gene_(j-1)
                else if seg_left > gene_(j-1)
                    t_left = gene_j
                else # find the new window
                    middle = round((i+j)/2.0)
                    if seg_left < gene_middle
                        create new search window
                           [gene_i, gene_middle]
                    else # seg_left > gene_middle
                        create new search window
                           [gene_middle, gene_j]
                    finally, new the new window to iterate, until t_left is found

          iii) continue with the seg_right position; the target gene is noted 't_right'
          iv) target window (one_side of window boundaries is moved at a time)
              - starting window [t_left, gene_(n-1)]
              - checking boundary conditions
                  if seg_right < t_left or in t_left
                      t_right = t_left
                  else if seg_right > gene_(n-1)
                      t-right = gene_(n-1)
                  else:
                      starting iteration below
              - general window [gene_i, gene_j]
              - if seg_right in gene_i
                    t_right = gene_i
                else if seg_right in gene_(i+1)
                    t_right = gene_(i+1)
                else if seg_right < gene_(i+1)
                    t_right = gene_i
                else if seg_right in gene_j
                    t_right = gene_j
                else if seg_right in gene_(j-1)
                    t_right = gene_(j-1)
                else if seg_right > gene_(j-1)
                    t_right = gene_(j-1)
                else # find the new window
                    middle = round((i+j)/2.0)
                    if seg_right < gene_middle
                        create new search window
                           [gene_i, gene_middle]
                    else # seg_right > gene_middle
                        create new search window
                           [gene_middle, gene_j]
                    finally, new the new window to iterate, until t_right is found

          v) target gene list is [t_left, t_right]
      d) insert the same val into each matched genes, step (3)


********************************************************************
********************************************************************

MIRNA array

*********************************************************************
*********************************************************************

    ** data URL **
    
http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein_normalization__data.Level_3.${DATE_SHORT}00.0.0.tar.gz

   
    ** file structure in tar.gz **
    illumina HiSeqMANIFEST.txt
    ACC.mirnaseq__illuminahiseq_mirnaseq__bcgsc_ca__Level_3__miR_gene_expression__data.data.txt
    
    ** Content **
    Hybridization REF  TCGA-OR-A5J1-01A-11R-A29W-13  TCGA-OR-A5J1-01A-11R-A29W-13  TCGA-OR-A5J1-01A-11R-A29W-13  TCGA-OR-A5J2-01A-11R-A29W-13 ...
    miRNA_ID                read_count              reads_per_million_miRNA_mapped       cross-mapped                read_count               ...
    hsa-let-7a-1             76213                         13484.031491                       N                         45441                 ...
     .......

   
    ** python code to parse probe_id to canonical gene name **
        -- script --
          MIRNAseq_parser.py
    
        --input file --   
          ACC.mirnaseq__illuminahiseq_mirnaseq__bcgsc_ca__Level_3__miR_gene_expression__data.data.txt

        --output file1 --
          mirna_probe.tsv
          [ call gene_symbol_as_geneID.py for map for synonyms to gene_symbol ]
          miRNA_probe_name miRNA_name canonical_name
          hsa-let-7a-1      LET7A-1    LET7A-1
          hsa-mir-551a      MIR551A    MIR551A
          hsa-mir-222       MIR222     MIR222A  [madeup]
          hsa-mir-222       MIR222     MIR222B  [madeup]
          ......

        --output file2 --
          mirna_data.tsv
           
          ** Content **
        Hybridization REF  TCGA-OR-A5J1-01A-11R-A29W-13   TCGA-OR-A5J2-01A-11R-A29W-13            ...
        miRNA_ID            reads_per_million_miRNA_mapped      reads_per_million_miRNA_mapped    ...
        hsa-let-7a-1        13484.031491                              34.234                      ...
         .......

         
    
    ** scidb array schema **

    TCGA_${DATE}_ILLUMINAHISEQ_MIRNASEQ_PROBE_STD
    <probe_name:string,
    reference_chromosome:string,
    genomic_start:int64,
    genomic_end:int64,
    reference_gene_symbols:string>
    [gene_id=0:*,1000000,0,
    illuminahiseq_mirnaseq_probe_id=0:*,1000,0]
    
    TCGA_${DATE}_ILLUMINAHISEQ_MIRNASEQ_STD
    <value:double null>
    [tumor_type_id=0:*,1,0,
     sample_id=0:*,1000,0,
     illuminahiseq_mirnaseq_probe_id=0:*,1000]"

   
        **  loading scripts **
    
    https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/load_mirna.sh
    
    include-
    update/insert: TCGA_{DATE}_PATIENT_STD
    update/insert: TCGA_{DATE}_SAMPLE_STD
    update/insert: TCGA_{GATE}_GENE_STD

********************************************************************
********************************************************************

PROTEIN array

*********************************************************************
*********************************************************************

    ** data URL **
    
 wget -nv -P ${path_downloaded}  http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein_normalization__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
    
    ** file structure in tar.gz **
    MANIFEST.txt
    ACC.protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein_normalization__data.data.txt
    
    ** Content **
    Sample REF      TCGA-OR-A5J2-01A-21-A39K-20     TCGA-OR-A5J3-01A-21-A39K-20
    Composite Element REF   Protein Expression      Protein Expression 
    14-3-3_beta-R-V 0.22334275225   -0.14206455625
    14-3-3_epsilon-M-C      -0.0195729252500001     -0.12290085275
    Acetyl-a-Tubulin-Lys40-R-C      0.0788483787499997      -0.10424065275
    ADAR1-M-V       0.16202263575   0.05806042625
    Annexin-1-M-E   0.16743429375   -0.0375481667499998
    ......

   
    ** python code to parse probe_id to canonical gene name **
        -- script --
          protein_exp_parser.py
    
        --input file --   
         ACC.protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein_normalization__data.data.txt
         
        --output file --
          protein_probe.tsv
          [ call gene_symbol_as_geneID.py for map for synonyms to gene_symbol ]
          probe_name       gene_name canonical_name
          14-3-3_beta-R-V   14-3-3_beta    14-3-3_beta
          ADAR1-M-V         ADAR1          ADAR1
          K7-M-E            K7             AK7  [madeup]
          K7-M-E            K7             AKA  [madeup]
          ......

         
    
    ** scidb array schema **

    TCGA_${DATE}_PROTEIN_EXP_PROBE_STD
    <probe_name:string,
    reference_chromosome:string,
    genomic_start:int64,
    genomic_end:int64,
    reference_gene_symbols:string>
    [gene_id=0:*,1000000,0,
    protein_exp_probe_id=0:*,1000,0]
    
    TCGA_${DATE}_PROTEIN_EXP_STD
    <value:double null>
    [tumor_type_id=0:*,1,0,
     sample_id=0:*,1000,0,
     protein_exp_probe_id=0:*,1000]"

   
        **  loading scripts **
    
    https://github.com/Paradigm4/variant_warehouse/load_tcga/tcga_dev/load_protein.sh
    
    include-
    update/insert: TCGA_{DATE}_PATIENT_STD
    update/insert: TCGA_{DATE}_SAMPLE_STD
    update/insert: TCGA_{GATE}_GENE_STD


