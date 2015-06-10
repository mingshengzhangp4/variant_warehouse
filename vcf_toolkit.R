# BEGIN_COPYRIGHT
# 
# Copyright © 2014 Paradigm4, Inc.
# This script is used in conjunction with the Community Edition of SciDB.
# SciDB is free software: you can redistribute it and/or modify it under the terms of the Affero General Public License, version 3, as published by the Free Software Foundation.
#
# END_COPYRIGHT

library(scidb)
scidbconnect()

#You need to at least load one 1000G file for these to work.
#An example_20k vcf file is provided.
KG_CHROMOSOME = scidb("KG_CHROMOSOME")
KG_VARIANT    = scidb("KG_VARIANT")
KG_GENOTYPE   = scidb("KG_GENOTYPE")
KG_SAMPLE     = scidb("KG_SAMPLE")

#Load the populations file
KG_POPULATION = scidb("KG_POPULATION")

#Need to run load_gene.sh for this
GENE = scidb("GENE_37")


#simple one-liner to start: count the 1000G variants grouped by chromosome
#note the chromosome_id assignment will depend on the order in which data is loaded
count_variants_by_chromosome= function()
{
  iqdf(merge(KG_CHROMOSOME,aggregate(KG_VARIANT, FUN="count(*)", by="chromosome_id")))
}

#Get data for all variants in a particular region.
#Result is returned as a data.frame; overlapping variants may be included with a flag
get_variants_in_region = function( chromosome = '10', start = 100000, end = 110000, overlaps=TRUE)
{
  if (overlaps == FALSE)
  {
    result = KG_VARIANT[, between(start,end), between(start,end),, redim=FALSE]
  }
  else
  {
    result = KG_VARIANT[, between(0,end), between(start,Inf),, redim=FALSE]
  }
  result = merge(result, subset(KG_CHROMOSOME, sprintf("chromosome='%s'", chromosome)))
  result = result[KG_CHROMOSOME %==% chromosome,,,,redim=FALSE]
  result = project(result, c("chromosome", "reference", "alternate", "af"))
  result = result[]
  print(nrow(result))
  return(result)
}

#Lookup gene coordinates by name, return as a 1-row data.frame
lookup_gene = function(gene = 'TUBB8')
{
  gene_info = subset(GENE, sprintf("gene='%s'", gene))
  cnt = count(gene_info)
  if (cnt != 1)
  {
    stop("Couldn't find this gene in the database")
  }
  return(gene_info[])
}

#Lookup region for gene, then lookup variants for that region
get_variants_in_gene = function (gene = 'TUBB8', overlaps=FALSE)
{
  gene_info = lookup_gene(gene)
  return (get_variants_in_region(gene_info$chromosome, gene_info$start, gene_info$end, overlaps))
}

#Look up all non-reference variants for a sample
#This typically returns a few hundred thousand positions per chromosome
#Exercise for the reader: restrict this to specific position ranges
get_variants_for_sample = function(sample = 'HG00100', n=25)
{
  result = subset(KG_GENOTYPE, "allele_1 or allele_2")[,,,,KG_SAMPLE==sample,redim=FALSE]
  result = merge(KG_VARIANT, result)
  result = unpack(result)
  result = project(result, c("start", "reference", "alternate", "allele_1", "allele_2", "phase"))
  iqdf(result, n=n)
}

#Lookup all samples that are homozygous or heterozygous for a particular variant
#Try this position with "alternate='A'"
get_samples_for_variant = function(chromosome = '10', start=332231, alternate='T')
{
  iqdf(
    project(
      merge(
        merge(
         subset(KG_GENOTYPE, 'allele_1 or allele_2'),
         project(subset(KG_VARIANT[KG_CHROMOSOME==chromosome, start,,], sprintf("alternate='%s'",alternate)), c("reference", "alternate"))
        ),
        KG_SAMPLE
      ),
      c("sample", "reference", "alternate", "allele_1", "allele_2")
    )
  )
}

#Select a set of variants for a region and then compute the allele frequencies, grouped by
#variant and population. This lends itself to a neat verification step. The total allele count
#(ac) is present in the data, and the per-population allele count is computed by SciDB on the fly.
#For example:
#chrom  pos               ref         alt   ac(total)   population        ac by population      
#3      2000226           G           A     46          AFR               0
#3      2000226           G           A     46          AMR               0
#3      2000226           G           A     46          EAS               1
#3      2000226           G           A     46          EUR               0
#3      2000226           G           A     46          SAS               45
grouped_allele_count = function (chromosome='10', start = 100000, end = 120000, overlaps=TRUE)
{
  if (overlaps == FALSE)
  {
    genotypes = KG_GENOTYPE[, between(start,end), between(start,end),,, redim=FALSE]
  }
  else
  {
    genotypes = KG_GENOTYPE[, between(0,end), between(start,Inf),,, redim=FALSE]
  }
  genotypes = bind(genotypes, "ac", "iif(allele_1 and allele_2, 2, iif(allele_1 or allele_2, 1, 0))")
  genotypes = merge(genotypes, subset(KG_CHROMOSOME, sprintf("chromosome='%s'", chromosome)))
  genotypes = merge(genotypes, KG_POPULATION)
  counts = aggregate(genotypes, FUN="max(population) as population, sum(ac) as population_ac", 
                        by=list("chromosome_id", "start", "end", "alternate_id", "population_id"))
  r = merge(merge(project(KG_VARIANT, c("reference", "alternate", "ac")), KG_CHROMOSOME), counts)[]
  #Get rid of some "noisy" columns - chromosome_id, alternate_id, population_id - for prettier display
  result=data.frame(r$chromosome, r$start, r$reference, r$alternate, r$ac, r$population, r$population_ac)
  return(result)
}

grouped_allele_count_in_gene = function(gene = 'TUBB8', overlaps=TRUE)
{
  gene_info = lookup_gene(gene)
  return (grouped_allele_count(gene_info$chromosome, gene_info$start, gene_info$end, overlaps))
}

#Generic range join over genomic ranges
#left and right are input arrays, left should be the larger
#left and right must both contain "chromosome_id", "start" and "end" as either attributes (non-null int64) or dimensions
#left_attributes and right_attributes are lists of attributes to extract from left and right
#do not include chromosome_id, start or end in the left_attributes or right_attributes_lists
#Returns an unevaluated array of the form 
#  <LEFT.start:int64,  LEFT.end:int64,  [left_attributes], 
#   RIGHT.start:int64, RIGHT.end:int64, [right_attributes]>
#  [chromosome_id, bucket, left_synthetic, right_synthetic]
#For example usage, see next function
range_join = function(left, right, left_attributes, right_attributes, min_bucket_size=1000000, overlaps=TRUE)
{
  if ("chromosome_id" %in% dimensions(left) == FALSE  && "chromosome_id" %in% scidb_attributes(left) == FALSE)
  { stop("Left array does not contain a dimension or attribute 'chromosome_id'") }
  if ("start" %in% dimensions(left) == FALSE  && "start" %in% scidb_attributes(left) == FALSE)
  { stop("Left array does not contain a dimension or attribute 'start'") }
  if ("end" %in% dimensions(left) == FALSE  && "end" %in% scidb_attributes(left) == FALSE)
  { stop("Left array does not contain a dimension or attribute 'end'") }
  if ("chromosome_id" %in% dimensions(right) == FALSE  && "chromosome_id" %in% scidb_attributes(right) == FALSE)
  { stop("Left array does not contain a dimension or attribute 'chromosome_id'") }
  if ("start" %in% dimensions(right) == FALSE  && "start" %in% scidb_attributes(right) == FALSE)
  { stop("Left array does not contain a dimension or attribute 'start'") }
  if ("end" %in% dimensions(right) == FALSE  && "end" %in% scidb_attributes(right) == FALSE)
  { stop("Left array does not contain a dimension or attribute 'end'") }
  
  left_stats  =  aggregate(bind(left,   "length", "end - start + 1"), FUN="max(length) as length, count(*) as count")[]
  right_stats =  aggregate(bind(right,  "length", "end - start + 1"), FUN="max(length) as length, count(*) as count")[]
  bucket_size = max(min_bucket_size, left_stats$length, right_stats$length)+1

  left_types = c()
  for (attr in left_attributes)
  {
    idx = which(scidb_attributes(left) %in% attr)
    if (length(idx) == 0)
    { left_types = c(left_types, "int64") }
    else
    { left_types = c(left_types, sprintf("%s null", scidb_types(left)[idx])) }
  }
  left_attributes = c(left_attributes, "start", "end")
  left_types      = c(left_types,      "int64", "int64")
  left_attr_schema = sprintf("<%s>", paste(paste(left_attributes, left_types, sep = ":"), collapse = ", "))

  right_types = c()
  for (attr in right_attributes)
  {
    idx = which(scidb_attributes(right) %in% attr)
    if (length(idx) == 0)
    { right_types = c(right_types, "int64") }
    else
    { right_types = c(right_types, sprintf("%s null", scidb_types(right)[idx])) }
  }
  right_attributes = c(right_attributes, "start", "end")
  right_types      = c(right_types,      "int64", "int64")
  right_attr_schema = sprintf("<%s>", paste(paste(right_attributes, right_types, sep = ":"), collapse = ", "))

  filter_condition = "LEFT.start <= RIGHT.end and RIGHT.start <= LEFT.end"
  if (overlaps == FALSE)
  {
    filter_condition = "LEFT.start >= RIGHT.start and LEFT.end <= RIGHT.end"
  }
  
  res = scidb(sprintf("
                       filter(
                        cross_join(
                         redimension(
                          apply(
                            cross_join( 
                             %s,
                             build(<f:bool>[offset=0:1,2,0], true)
                            ),
                           bucket, iif(offset = 0, start / %i, iif(end / %i <> start / %i, end / %i, null))
                          ),
                          %s [chromosome_id=0:*,1,0, bucket=0:*,1,0, left_synthetic = 0:*,%i,0]
                         ) as LEFT,
                         redimension(
                          apply(
                            cross_join( 
                             %s,
                             build(<f:bool>[offset=0:1,2,0], true)
                            ),
                           bucket, iif(offset = 0, start / %i, iif(end / %i <> start / %i, end / %i, null))
                          ),
                          %s [chromosome_id=0:*,1,0, bucket=0:*,1,0, right_synthetic = 0:*,%i,0]
                         ) as RIGHT,
                         LEFT.chromosome_id, RIGHT.chromosome_id,
                         LEFT.bucket, RIGHT.bucket
                        ),
                        %s and
                        (LEFT.start / %i = LEFT.end / %i or RIGHT.start / %i = RIGHT.end / %i or LEFT.start / %i = bucket) 
                       )",
                       left@name, bucket_size, bucket_size, bucket_size, bucket_size, left_attr_schema, 10 * bucket_size,
                       right@name, bucket_size, bucket_size, bucket_size, bucket_size, right_attr_schema, 10 * bucket_size,
                       filter_condition, bucket_size, bucket_size, bucket_size, bucket_size, bucket_size
  ))
}

#Locate variants that overlap with genes, and count the number of overlapping variants for each gene.
#Output the top 50 genes with the most variants.
#This represents a range join, which has many different use cases in genomics. For example,
#we can use the same procedure to compare two sets of variants and reference ranges, i.e. 
#give me variants in A that are fully enclosed by reference ranges in B - to detect de novo variants.
#We can also choose whether we want overlapping ranges or fully contained ranges, or maybe
#ranges that start at the same location, or maybe ranges whose overlap area exceeds some percentage.
#We're considering building a prototype operator for this task
rank_genes_by_variants = function(top_n = 50, overlaps = TRUE)
{
  res = range_join(KG_VARIANT, 
                   index_lookup(GENE, KG_CHROMOSOME, attr="chromosome", new_attr="chromosome_id"), 
                   left_attributes="qual", 
                   right_attributes="i", 
                   overlaps = overlaps)
  res = redimension(res, "<count:uint64 null> [i], count(*) as count")
  res = merge(GENE$gene, res)
  res = sort(res, attributes="count", decreasing=TRUE)
  iqdf(res, n=top_n)
}

#Select all variants whose af is greater than min_af and less than max_af; if variant_limit is
#specified, then select up to that many variants, chosen randomly. 
#<value> [sample_id, variant_number] where value is 2 if the variant is present in both alleles,
#1 if the variant is present in one allele or 0 otherwise. Then compute the first 3 principal 
#compnents of this matrix. Make a cute 3D plot.
#The plot uses https://github.com/bwlewis/rthreejs
pca = function(min_af = 0.1, max_af = 0.9, variant_limit, chunk_size=512)
{
  t0=proc.time()
  selected_variants = dimension_rename(project(unpack(subset(KG_VARIANT, sprintf("af>%f and af<%f", min_af, max_af))), c("chromosome_id, start, end, alternate_id")), old="i", new="dense_variant_id")
  if (!missing(variant_limit))
  {
    selected_variants = bind(selected_variants, "randomizer", "random()")
    selected_variants = sort(selected_variants, attributes="randomizer")
    selected_variants = selected_variants[between(0,variant_limit-1),]
    selected_variants = dimension_rename(selected_variants, old="n", new="dense_variant_id")
  }
  selected_variants = scidbeval(selected_variants, temp=TRUE)
  num_variants = count(selected_variants)
  num_samples = count(KG_SAMPLE)
  print(sprintf("%f %f: Found %i variants that fit the criteria; running [%i x %i]", 
                (proc.time()-t0)[3], (proc.time()-t0)[3], num_variants, num_variants, num_samples))
  t1=proc.time()
  
  redim_guide = redimension(selected_variants, sprintf("<dense_variant_id:int64> %s", scidb:::build_dim_schema(KG_VARIANT)))
  
  redim_matrix = bind(KG_GENOTYPE, "v", "double(iif(allele_1 and allele_2, 2.0, iif(allele_1 or allele_2, 1.0, 0.0)))")
  redim_matrix = merge(redim_matrix, redim_guide)
  redim_matrix = redimension(redim_matrix, sprintf("<v:double null> [sample_id = 0:%i,%i,0, dense_variant_id=0:%i,%i,0]", 
                                                   num_samples-1, chunk_size, num_variants-1, chunk_size))
  redim_matrix = replaceNA(redim_matrix)
  redim_matrix = scidbeval(redim_matrix, temp=TRUE)
  print(sprintf("%f %f: Built matrix", (proc.time()-t0)[3], (proc.time()-t1)[3]))
  t1=proc.time()
  
  centered = scidbeval(sweep(redim_matrix, 2, apply(redim_matrix, 2, mean)), temp=TRUE)
  print(sprintf("%f %f: Centered", (proc.time()-t0)[3], (proc.time()-t1)[3]))
  t1=proc.time()
  
  #Covariance if you like
  #Y = t(X)  # samples in columns
  #Y = Y - apply(Y,2,mean)
  #CV = crossprod(Y)/(nrow(Y) - 1)
  #image(CV)
  
  svded =  scidb(sprintf("gesvd(%s, 'left')", centered@name))
  svded = scidbeval(svded, temp=TRUE)
  print(sprintf("%f %f: SVD Computed", (proc.time()-t0)[3], (proc.time()-t1)[3]))
  
  download = svded[,0:2][]
  color = iqdf(project(bind(merge(KG_SAMPLE, KG_POPULATION), "color", "iif(population='AMR', 'blue', iif(population='AFR', 'red', iif(population='EUR', 'green', iif(population='EAS', 'purple', 'orange'))))"), "color"), n=Inf)$color
  
  #See https://github.com/bwlewis/rthreejs
  library(threejs)
  scatterplot3js(download, size=0.25, color=color)
}



# genes: character vector of genes to interrogate
# overlaps: find overlapping variants (TRUE) or interior variants (FALSE)
# Compute variants within a list of specified genes and return sums of
# allele counts grouped by gene and 1000 genome super population id.
variants_by_gene_and_population = function(genes, overlaps = TRUE)
{
  g37 = GENE[]
  g37 = g37[g37$gene %in% genes, ]
  g37$end = as.integer(g37$end)
  g37$start = as.integer(g37$start)
  GENE = as.scidb(g37, types=c("string","string","int64","int64"), nullable=FALSE)

  #Choose a bucket size that's bigger than the largest range of interest
  #subset GENE where name matches your list
  max_gene_length = aggregate(bind(GENE, "length", "end - start + 1"), FUN="max(length)")[]
  max_variant_length = aggregate(bind(KG_VARIANT, "length", "end - start + 1"), FUN="max(length)")[]
  bucket_size = max(max_gene_length, max_variant_length)+1
  
  #safe upper bound: no more than 5 features for each coordinate
  chunk_size = 5*bucket_size
  
  #Each variant goes into a bucket: if you need more per-variant data than just the count, add it here
  bucketed_variants = bind(KG_VARIANT, "bucket", sprintf("start / %i", bucket_size))
  bucketed_variants = bind(bucketed_variants, "variant_start", "start")
  bucketed_variants = bind(bucketed_variants, "variant_end",    "end")
  #include alternate_id, so you can use it later
  bucketed_variants = redimension(bucketed_variants, sprintf("<variant_start:int64, variant_end:int64, alternate_id:int64>[chromosome_id=0:*,1,0, bucket=0:*,1,0, vn=1:%i,%i,0]", chunk_size, chunk_size))
  bucketed_variants = scidbeval(bucketed_variants, temp=TRUE)
  
  #Now, each gene goes into *up to 3 adjacent buckets* For that, we cross it with a 3-cell vector
  bucketed_genes = index_lookup(GENE, KG_CHROMOSOME, "chromosome", "chromosome_id")
  bucketed_genes = merge(bucketed_genes, build("j", names=c("val","j"), dim=3, type="int64"))  #cross-product with 3-cell vector [(0),(1),(2)]
  bucketed_genes = bind(bucketed_genes, c("bucket", "gene_start", "gene_end"), c(sprintf("start / %i - 1 + j", bucket_size), "start", "end")) 
  bucketed_genes = subset(bucketed_genes, "bucket>=0") 
  bucketed_genes = redimension(bucketed_genes, sprintf("<gene:string, gene_start:int64, gene_end:int64>[chromosome_id=0:*,1,0, bucket=0:*,1,0, gn=1:%i,%i,0]", chunk_size, chunk_size))
  bucketed_genes = scidbeval(bucketed_genes, temp=TRUE)
  
  #Now bucketed_variants and bucketed_genes will join efficiently on [chromosome_id, bucket]
  #The shape of the join output is [chromosome_id, bucket, vn, gn]
  result = merge(bucketed_variants, bucketed_genes)
  
  #This filter will be run in parallel, comparing only genes and variants that fall in the same chromosome_id, bucket
  #You can also "carry" attribute values into the two arrays above and include an attribute comparison predicate here
  if (overlaps)
  {
    result = subset(result, "gene_start <= variant_end and variant_start <= gene_end")  
  }
  else
  {
    result = subset(result, "gene_start >= variant_start and gene_end <= variant_end")  
  }

  result = scidbeval(redimension(result, schema="<gene:string>[chromosome_id=0:*,1,0, variant_start=0:*,1000000,0, variant_end=0:*,1000000,0, alternate_id=0:*,20,0]"), temp=FALSE, name="result",gc=FALSE)
  result = dimension_rename(result, c("variant_start","variant_end"), c("start","end"))
  gt = bind(KG_GENOTYPE, "ac", "iif(allele_1,1,0) + iif(allele_2,1,0)")
  g = merge(gt, result)
  pop=redimension(KG_POPULATION,schema="<population:string> [sample_id=0:*,100,0,population_id=0:4,1,0]")
  g = merge(g, pop)
# count each allele combination by superpopulation and variant
  ans = scidbeval(redimension(g, schema="<ac_sum:int64 null>[chromosome_id=0:*,1,0, start=0:*,1000000,0, end=0:*,1000000,0, alternate_id=0:*,20,0, population_id=0:*,1,0]", FUN="sum(ac) as ac_sum"), temp=FALSE, name="ac", gc=FALSE)
  ans
}
