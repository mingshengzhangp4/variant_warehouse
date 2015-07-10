# BEGIN_COPYRIGHT
# 
# Copyright © 2014 Paradigm4, Inc.
# This App is used in conjunction with the Community Edition of SciDB.
# SciDB is free software: you can redistribute it and/or modify it under the terms of the Affero General Public License, version 3, as published by the Free Software Foundation.
#
# END_COPYRIGHT 

library('scidb')
library('ggplot2')
scidbconnect()

#Global array references
TCGA_DOWNLOAD_DATE = "2014_06_14"

TUMOR_TYPE         = scidb(sprintf("TCGA_%s_TUMOR_TYPE_STD",                        TCGA_DOWNLOAD_DATE))
GENE               = scidb(sprintf("TCGA_%s_GENE_STD",                              TCGA_DOWNLOAD_DATE))
SAMPLE_TYPE        = scidb(sprintf("TCGA_%s_SAMPLE_TYPE_STD",                       TCGA_DOWNLOAD_DATE))
SAMPLE             = scidb(sprintf("TCGA_%s_SAMPLE_STD",                            TCGA_DOWNLOAD_DATE))
MUTATION           = scidb(sprintf("TCGA_%s_MUTATION_STD",                          TCGA_DOWNLOAD_DATE))
CLINICAL           = scidb(sprintf("TCGA_%s_CLINICAL_STD",                          TCGA_DOWNLOAD_DATE))
DBNSFP             = scidb("DBNSFP_V2p9_VARIANT")

get_lof_data = function( tumors     = c('BRCA'),
                         clin_regex,
                         gene_list  = c('TP53', 'NOTCH1', 'NOTCH2', 'KRAS', 'NRAS', 'LRP1B', 'BRAF', 'ERBB4', 'PTEN', 'EGFR'),
                         KG_AF_threshold           = 0.01,
                         score_name                = "SIFT_converted_rankscore",
                         score_threshold           = 0.551)
{
  tumor_filter = "true"
  if (length(tumors) != 0)
  {
    tumor_filter = paste(sprintf("tumor_type_name = '%s'", tumors), collapse = " or ")  
  }
  gene_filter  = "true"
  if (length(gene_list) != 0)
  {
    gene_filter  = paste(sprintf("gene_symbol = '%s'", gene_list), collapse = " or ") 
  }
  clin_filter  = "true"
  if (!missing(clin_regex) && nchar(clin_regex) > 0)
  {
    clin_filter = sprintf("regex(value, '.*%s.*')", clin_regex)
  }
  outer_filter = sprintf("(%s is null or %s >= %f) and (KGp1_AF is null or KGp1_AF <= %f) and alt = tumor_allele",
                          score_name, score_name, score_threshold, KG_AF_threshold)
  query = sprintf("
 unpack(
  project(
   filter(
    cross_join(
     %s        as DBNSFP,
     redimension(
      apply(
       cross_join(
        cross_join(
           filter(%s, mutation_genomic_start = mutation_genomic_end and reference_allele<>'-' and tumor_allele<>'-') as MUTATION,
           project(filter(%s, %s), gene_symbol, chromosome_nbr) as GENE,
           MUTATION.gene_id, 
           GENE.gene_id
        ) as MUTATION,
        aggregate(
         cross_join(
          %s               as SAMPLE,
          aggregate(
           cross_join(
            filter(%s, %s) as CLINICAL,
            filter(%s, %s) as TUMOR_TYPE,
            CLINICAL.tumor_type_id,
            TUMOR_TYPE.tumor_type_id
           ),
           max(tumor_type_name) as tumor_type_name, tumor_type_id, patient_id
          ) as CLINICAL,
          SAMPLE.patient_id,
          CLINICAL.patient_id
         ),
         max(tumor_type_name) as tumor_type_name, max(sample_name) as sample_name, tumor_type_id, sample_id
        ) as SAMPLE,
       MUTATION.tumor_type_id, SAMPLE.tumor_type_id,
       MUTATION.sample_id,     SAMPLE.sample_id
      ),
      chromosome_id, iif(chromosome_nbr = 0, null, chromosome_nbr - 1)
     ),
     <tumor_type_name: string null, 
      sample_name:string null, 
      gene_symbol:string null,
      reference_allele: string null,
      tumor_allele:     string null>
     [chromosome_id=0:*,1,0, 
      mutation_genomic_start=0:*,10000000,0,
      mutation_nbr          =0:*,10000,0]
    ) as TCGA,
    DBNSFP.chromosome_id, TCGA.chromosome_id,
    DBNSFP.pos,           TCGA.mutation_genomic_start
   ),
   %s
  ),
  tumor_type_name, sample_name, gene_symbol, ref, alt
 ),
 z
)", DBNSFP@name, MUTATION@name, GENE@name, gene_filter, SAMPLE@name, CLINICAL@name, clin_filter, TUMOR_TYPE@name, tumor_filter, outer_filter)
  res = iqdf(query, n=Inf)
  
  res2 = data.frame(
       sprintf("%i:%i %s > %s",
        res$chromosome_id + 1,
        res$pos,
        res$ref,
        res$alt
       ),
       res$tumor_type_name,
       res$sample_name,
       res$gene_symbol
    )
  names(res2) = c("variant", "tumor", "sample", "gene")
  res2 = unique(res2)
  
  return(res2)
}

full_lof_query = function(tumors     = c('BRCA'),
                          clin_regex,
                          gene_list  = c('TP53', 'NOTCH1', 'NOTCH2', 'KRAS', 'NRAS', 'LRP1B', 'BRAF', 'ERBB4', 'PTEN', 'EGFR'),
                          KG_AF_threshold           = 0.01,
                          score_name                = "SIFT_converted_rankscore",
                          score_threshold           = 0.551)
{
  t1=proc.time();
  alts   = get_lof_data(tumors, clin_regex, gene_list, KG_AF_threshold, score_name, score_threshold)
  gene   = alts$gene
  sample = alts$sample
  tumor  = alts$tumor
  num_rows    = nrow(alts)
  num_tumors  = length(levels(tumor))
  
  unique_gene   = levels(gene)
  unique_sample = levels(sample)
  num_genes     = length(unique_gene)
  num_samples   = length(unique_sample)
  gene_id       = match(gene,  unique_gene) 
  sample_id     = match(sample,unique_sample)
  
  reupload = as.scidb(data.frame(sample_id, gene_id), types=c("int64", "int64"))
  reupload = bind(reupload, "mutated", "true")
  reupload = redimension(reupload, sprintf("<mutated:bool> 
                                           [gene_id=1:%i,250,0, sample_id=1:%i,250,0]", num_genes, num_samples))
  reupload = scidb(sprintf("merge(%s, build(<x: bool> [gene_id=1:%i,250,0, sample_id=1:%i, 250, 0], false))", reupload@name, num_genes, num_samples))
  reupload = scidbeval(reupload, temp=TRUE)
  
  triangle = scidbeval(scidb(
    sprintf(
      "filter(
        cast(
         aggregate(
          apply(
           cross_join(
            %s as left,
            %s as right,
            left.sample_id,
            right.sample_id
           ),
           mutated_both,    double(iif(left.mutated=true and right.mutated=true,  1.0, 0.0)),
           mutated_left,    double(iif(left.mutated=true and right.mutated=false, 1.0, 0.0)),
           mutated_right,   double(iif(left.mutated=false and right.mutated=true, 1.0, 0.0))
          ),
          sum(mutated_both)  as mutated_both,
          sum(mutated_left)  as mutated_left,
          sum(mutated_right) as mutated_right,
          left.gene_id,
          right.gene_id
         ),
         <mutated_both:double null, mutated_left:double null, mutated_right:double null> [gene_id_1, gene_id_2]
        ),
        gene_id_2 > gene_id_1
      )", reupload@name, reupload@name)), temp=TRUE)
  
  fisher_result = iqdf(
    scidb(sprintf(
      "apply(
        apply(
         %s, 
         not_mutated,
         %i - (mutated_both + mutated_left + mutated_right)
        ),
        pval, fishertest_p_value(mutated_both, mutated_both+mutated_left, mutated_right+not_mutated, mutated_both+mutated_right, 'two.sided'),
        estimate, fishertest_odds_ratio(mutated_both, mutated_both+mutated_left, mutated_right+not_mutated, mutated_both+mutated_right)
       )",
       triangle@name, num_samples
      )), n=Inf
    )
  fisher_result = data.frame( gene_1 = unique_gene[fisher_result$gene_id_1],
                              gene_2 = unique_gene[fisher_result$gene_id_2],
                              mutated_both  = fisher_result$mutated_both,
                              mutated_left  = fisher_result$mutated_left,
                              mutated_right = fisher_result$mutated_right,
                              not_mutated   = fisher_result$not_mutated,
                              pval          = fisher_result$pval,
                              estimate      = fisher_result$estimate)                          
  result = list(alts, fisher_result)
  print(proc.time()-t1)
  return(result)
}
