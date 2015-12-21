#!/bin/bash
DATE="2015_06_01"

 iquery -anq "remove(TCGA_${DATE}_TUMOR_TYPE_STD)"   > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_SAMPLE_TYPE_STD)"  > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_SAMPLE_STD)"       > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_PATIENT_STD)"      > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_CLINICAL_STD)"     > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_GENE_STD)"         > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_MUTATION_STD)"     > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_RNAseqV2_STD)"     > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_RNAseq_STD)"     > /dev/null 2>&1
 
 
 iquery -anq "remove(TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD)" > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_HUMANMETHYLATION450_STD)" > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_GENOME_WIDE_SNP_6_PROBE_STD)" > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_GENOME_WIDE_SNP_6_STD)" > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_ILLUMINAHISEQ_MIRNASEQ_PROBE_STD)" > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_ILLUMINAHISEQ_MIRNASEQ_STD)" > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_PROTEIN_EXP_PROBE_STD)" > /dev/null 2>&1
 iquery -anq "remove(TCGA_${DATE}_PROTEIN_EXP_STD)" > /dev/null 2>&1
 
 
 
 
 iquery -aq "create array TCGA_${DATE}_TUMOR_TYPE_STD  <tumor_type_name:string, full_name:string> [tumor_type_id=0:*,1000000,0]"
 iquery -aq "create array TCGA_${DATE}_SAMPLE_TYPE_STD <code:string,definition:string,short_letter_code:string> [sample_type_id=0:*,1000000,0]"
 iquery -aq "create array TCGA_${DATE}_SAMPLE_STD <sample_name:string> [tumor_type_id=0:*,1000000,0, patient_id=0:*,1000,0, sample_type_id=0:*,1000000,0,sample_id=0:*,1000,0]"
 iquery -aq "create array TCGA_${DATE}_PATIENT_STD  <patient_name:string> [tumor_type_id=0:*,1000000,0,patient_id=0:*,1000,0]"



 iquery -aq "create array TCGA_${DATE}_CLINICAL_STD <key:string,value:string null> [tumor_type_id=0:*,1,0,clinical_line_nbr=0:*,1000,0,patient_id=0:*,1000,0]"
 
 iquery -anq "create array TCGA_${DATE}_GENE_STD
 <gene_symbol: string null,
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
  other_locations: string null>
 [gene_id=0:*, 1000000,0]"
 
 
 
 iquery -aq "create array TCGA_${DATE}_MUTATION_STD
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
 
 
 iquery -anq "create array TCGA_${DATE}_RNAseqV2_STD
  <RNA_expressionLevel:double null>
  [tumor_type_id=0:*,1,0,
   sample_id=0:*,1000,0,
   gene_id=0:*,1000000,0]"
 
 iquery -anq "create array 
  TCGA_${DATE}_RNAseq_STD
  <raw_count:double null,
   scaled_estimate:double null>
  [tumor_type_id=0:*,1,0,
   sample_id=0:*, 1000, 0,
   gene_id=0:*,1000000,0]"
 
 
 # iquery -aq "remove(methyl_probe_index)"
 # iquery -aq "create array methyl_probe_index
 # <probe_name:string>
 # [probe_id=0:*, 1000000,0]"
 
 iquery -anq "create array
 TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD
 <probe_name:string null,
 reference_chromosome:string null,
 genomic_start:int64 null,
 genomic_end:int64 null,
 reference_gene_symbols:string null>
 [gene_id=0:*,1000000,0,
 humanmethylation450_probe_id=0:*,1000,0]"
 
 iquery -anq "create array
  TCGA_${DATE}_HUMANMETHYLATION450_STD
  <value:double null>
  [tumor_type_id=0:*,1,0,
   sample_id=0:*,1000,0,
   humanmethylation450_probe_id=0:*,1000,0]"
 
 
 # iquery -aq "remove(snp6_probe_index)"
 # iquery -aq "create array snp6_probe_index
 # <probe_name:string>
 # [probe_id=0:*, 1000000,0]"
 
 iquery -anq "create array
 TCGA_${DATE}_GENOME_WIDE_SNP_6_PROBE_STD
 <probe_name:string null,
 reference_chromosome:string null,
 genomic_start:int64 null,
 genomic_end:int64 null,
 reference_gene_symbols:string null>
 [gene_id=0:*,1000000,0,
 genome_wide_snp_6_probe_id=0:*,1000,0]"
 
 iquery -anq "create array
  TCGA_${DATE}_GENOME_WIDE_SNP_6_STD
  <value:double null>
  [tumor_type_id=0:*,1,0,
   sample_id=0:*,1000,0,
   genome_wide_snp_6_probe_id=0:*,1000,0]"




iquery -anq "create array
TCGA_${DATE}_ILLUMINAHISEQ_MIRNASEQ_PROBE_STD
<probe_name:string null,
reference_chromosome:string null,
genomic_start:int64 null,
genomic_end:int64 null,
reference_gene_symbols:string null>
[gene_id=0:*,1000000,0,
illuminahiseq_mirnaseq_probe_id=0:*,1000,0]"

iquery -anq "create array
 TCGA_${DATE}_ILLUMINAHISEQ_MIRNASEQ_STD
 <value:double null>
 [tumor_type_id=0:*,1,0,
  sample_id=0:*,1000,0,
  illuminahiseq_mirnaseq_probe_id=0:*,1000,0]"





 iquery -anq "create array
 TCGA_${DATE}_PROTEIN_EXP_PROBE_STD
 <probe_name:string null,
 reference_chromosome:string null,
 genomic_start:int64 null,
 genomic_end:int64 null,
 reference_gene_symbols:string null>
 [gene_id=0:*,1000000,0,
 protein_exp_probe_id=0:*,1000,0]"
 
 iquery -anq "create array
  TCGA_${DATE}_PROTEIN_EXP_STD
  <value:double null>
  [tumor_type_id=0:*,1,0,
   sample_id=0:*,1000,0,
   protein_exp_probe_id=0:*,1000,0]"
 
