#!/bin/bash

if [ $# -ne 4 ]; then
 echo "Need 4 arguments: date, tumor, C_pos,P_pos"
 exit 1
fi

DATE=$1
TUMOR=$2
C_pos=$3
P_pos=$4


DATE_SHORT=`echo $DATE | sed  "s/_//g"`
echo $DATE_SHORT
cwd=`pwd`
path_downloaded=${cwd}/tcga_download
mkdir -p ${path_downloaded}


##  gdac.broadinstitute.org_UVM.Mutation_Packager_Calls.Level_3.2015060100.0.0.tar.gz

 { wget -nv -P ${path_downloaded}  http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Mutation_Packager_Calls.Level_3.${DATE_SHORT}00.0.0.tar.gz
}||{
echo "The file requested does not exist:"
echo "http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Mutation_Packager_Calls.Level_3.${DATE_SHORT}00.0.0.tar.gz"
echo "exiting..."
exit 1
}


 tar -zxvf ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Mutation_Packager_Calls.Level_3.${DATE_SHORT}00.0.0.tar.gz --directory ${path_downloaded}/


## field map-
## $16: Tumor-Sample-Barcode  $1: Hugo-Symbol $4: NCBI_BUILD $6: Start_position $7: End_position
## $9: variant-classification $10: variant-type $11: reference-allele $12: Tumor-seq-allele1
## $13: Tumor-sequence-allele2
 
 AWK_STRING='{print $16 "\t" $1 "\t" $4 "\t" $6 "\t" $7 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $'$C_pos' "\t" $'$P_pos'}'


rm -f  "${path_downloaded}/${TUMOR}_mutation.tsv"

  for file in `ls ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Mutation_Packager_Calls.Level_3.${DATE_SHORT}00.0.0 | grep -i maf`; do
      cat ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Mutation_Packager_Calls.Level_3.${DATE_SHORT}00.0.0/$file | tail -n +2 | awk -F "\t" "${AWK_STRING}" >> "${path_downloaded}/${TUMOR}_mutation.tsv" 
  done


FILE="${path_downloaded}/${TUMOR}_mutation.tsv"

iquery -anq "remove(TCGA_MUTATION_LOAD_BUF)"    > /dev/null 2>&1
  
  
  
  iquery -anq "create temp array TCGA_MUTATION_LOAD_BUF
  <sample_:string null,
   gene_:string null,
   release_:string null,
   start_:string null,
   end_:string null,
   mtype_:string null,
   type_: string null,
   ref_: string null,
   tumor_:string null,
   tumor2_:string null,
   c_pos_:string null,
   p_pos_:string null,
   error: string null>
  [source_instance_id = 0:*,1,0,
   chunk_number       = 0:*,1,0,
   line_number        = 0:*,1000,0]"
  
  
  
  
  iquery -anq "
  store(
   parse(
    split('$FILE', 'lines_per_chunk=1000'),
    'chunk_size=1000', 'num_attributes=12'
   ),
   TCGA_MUTATION_LOAD_BUF
  )" 
  
  
  
  #Insert new patients
  
  iquery -anq "
  insert(
   redimension(
    index_lookup(
     apply(
      cross_join(
       uniq(
        sort(
         project(
          filter(
           index_lookup(
             apply(
              TCGA_MUTATION_LOAD_BUF,
              patient_name, 
              substr(sample_, 0, 12)
             ) as A,
             redimension(TCGA_${DATE}_PATIENT_STD, <patient_name:string> [patient_id=0:*,1000000,0]) as B,
             A.patient_name, 
             pid
           ),
           pid is null
          ),
          patient_name
         )
        )
       ) as new_patients,
       aggregate( apply(TCGA_${DATE}_PATIENT_STD, pid, patient_id), max(pid) as mpid)
      ),
      ttn, '${TUMOR}',
      patient_id, iif(mpid is null, new_patients.i, mpid+1+new_patients.i)
     ),
     TCGA_${DATE}_TUMOR_TYPE_STD,
     ttn,
     tumor_type_id
    ),
    TCGA_${DATE}_PATIENT_STD
   ),
   TCGA_${DATE}_PATIENT_STD
  )"
  

#Insert new gene entries we havent seen before
#Me thinks we need a new gene list
#Lord this is messy


iquery -anq "
insert(
  redimension(
    apply(
      cross_join(
        substitute(
          uniq(
            sort(
              project(
                filter(
                  index_lookup(
                    TCGA_MUTATION_LOAD_BUF,
                    uniq(sort(
                      redimension(
                        substitute(
                          TCGA_${DATE}_GENE_STD,
                          build(<subval:string>[i=0:0,1,0],'_'),
                          gene_symbol
                          ),
                        <gene_symbol:string> [gene_id=0:*,1000000,0]
                        )
                     )) as B,
                    gene_, 
                    gid
                    ),
                  gid is null
                  ),
                gene_
                )
              )
            ),
          build(<subval:string>[i=0:0,1,0], '_'),
          gene_ 
          ) as new_genes,

        aggregate( apply(TCGA_${DATE}_GENE_STD, gid, gene_id), max(gid) as mgid)
      ),
      gene_symbol, gene_,
      gene_id, iif(mgid is null, new_genes.i, mgid+1+new_genes.i),
      entrez_geneID, int64(0),
      start_, '_',
      end_, '_',
      strand_, '_',
      hgnc_synonym, '_',
      synonym, '_',
      dbXrefs, '_',
      cyto_band, '_',
      full_name, '_',
      type_of_gene, '_',
      chrom, '_',
      other_locations, '_'
      ),
    TCGA_${DATE}_GENE_STD
    ),
  TCGA_${DATE}_GENE_STD
  )"


#Insert new samples
iquery -anq "
insert(
 redimension(
  index_lookup(
   index_lookup(
    index_lookup(
     apply(
      cross_join(
       uniq(
        sort(
         project(
          filter(
           index_lookup(
             apply(
              TCGA_MUTATION_LOAD_BUF,
              sample_name, 
              substr(sample_, 0, 15)
             ) as A,
             redimension(TCGA_${DATE}_SAMPLE_STD, <sample_name:string> [sample_id=0:*,1000000,0]) as B,
             A.sample_name, 
             sid
           ),
           sid is null
          ),
          sample_name
         )
        )
       ) as new_samples,
       aggregate( apply(TCGA_${DATE}_SAMPLE_STD, sid, sample_id), max(sid) as msid)
      ),
      ttn, '${TUMOR}',
      sample_id, iif(msid is null, new_samples.i, msid+1+new_samples.i),
      patient_name, substr(sample_name, 0, 12),
      sample_code,  substr(sample_name, 13, 2)
     ) as W,
     redimension(TCGA_${DATE}_SAMPLE_TYPE_STD, <code:string> [sample_type_id=0:*,1000,0]),
     W.sample_code,
     sample_type_id
    ),
    redimension(TCGA_${DATE}_PATIENT_STD, <patient_name:string> [patient_id=0:*,1000000,0]),
    W.patient_name, 
    patient_id 
   ),
   TCGA_${DATE}_TUMOR_TYPE_STD,
   W.ttn,
   tumor_type_id
  ),
  TCGA_${DATE}_SAMPLE_STD
 ),
 TCGA_${DATE}_SAMPLE_STD
)"


iquery -anq "
insert(
 redimension(
  apply(
   index_lookup(
    index_lookup(
     index_lookup(
      apply(
       TCGA_MUTATION_LOAD_BUF,
       sample_name, substr(sample_, 0, 15),
       GRCh_release, release_,
       mutation_genomic_start, dcast(start_, int64(null)),
       mutation_genomic_end,   dcast(end_, int64(null)),
       mutation_type, mtype_,
       variant_type,  type_, 
       reference_allele,  ref_,
       tumor_allele, iif(tumor_= ref_, tumor2_, tumor_),
       c_pos_change, c_pos_,
       p_pos_change, p_pos_,
       ttn, '${TUMOR}'
      ) as A,
      redimension(TCGA_${DATE}_SAMPLE_STD, <sample_name:string> [sample_id=0:*,1000000,0]) as B,
      A.sample_name,
      sample_id
     ),
     TCGA_${DATE}_TUMOR_TYPE_STD,
     A.ttn,
     tumor_type_id
    ),
    substitute(
        redimension(TCGA_${DATE}_GENE_STD, <gene_symbol:string null>[gene_id=0:*,10000,0]),
        build(<subval:string>[i=0:0,1,0],'_'),
        gene_symbol
    ),
    A.gene_,
    gene_id_
   ),
   gene_id, iif(gene_id_ is null, 0, gene_id_)
  ),
  TCGA_${DATE}_MUTATION_STD
 ),
 TCGA_${DATE}_MUTATION_STD
)"

 
iquery -anq "remove(TCGA_MUTATION_LOAD_BUF)"    > /dev/null 2>&1
rm -f  "${path_downloaded}/${TUMOR}_mutation.tsv"
rm -rf ${path_downloaded}

