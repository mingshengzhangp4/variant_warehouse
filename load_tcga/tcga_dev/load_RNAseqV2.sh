#!/bin/bash

if [ $# -ne 2 ]; then
 echo "Need 4 arguments: date, tumor"
 exit 1
fi

DATE=$1
TUMOR=$2
## C_pos=$3
## P_pos=$4


DATE_SHORT=`echo $DATE | sed  "s/_//g"`
echo $DATE_SHORT



iquery -anq "create array TCGA_${DATE}_RNAseqV2_STD
<expression:string null>
[tumor_type_id = 0:*,1000000,0,
 sample_id = 0:*,1000,0,
 gene_id = 0:*, 10000, 0]"



path_downloaded=/home/mzhang/Documents/tcga_download

##  gdac.broadinstitute.org_UVM.Mutation_Packager_Calls.Level_3.2015060100.0.0.tar.gz


## wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.2015060100.0.0.tar.gz



##wget -P /home/mzhang/Documents/tcga_download  http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
##
##  echo "downloaded RNAseq file..."
##  select yn in "yes" "no"; do
##      case $yn in
##          yes) break;;
##          no ) exit 1 ;;
##      esac
##  done
 

##  tar -zxvf /home/mzhang/Documents/tcga_download/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0.tar.gz --directory /home/mzhang/Documents/tcga_download/


 ## echo "extracted RNAseq file..."
 ## select yn in "yes" "no"; do
 ##     case $yn in
 ##         yes) break;;
 ##         no ) exit 1 ;;
 ##     esac
 ## done
 



##  AWK_STRING='{print $16 "\t" $1 "\t" $4 "\t" $6 "\t" $7 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $'$C_pos' "\t" $'$P_pos'}'

## AWK_STRING='{print $16 "\t" $1 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $9 "\t" $10 "\t" $11 "\t" $12 "\t" $13 "\t" $'$C_pos' "\t" $'$P_pos'}'


## rm "${path_downloaded}/${TUMOR}_mutation.tsv"




  for file in `ls ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0 | grep -i ${TUMOR}`; do
      column_type=`cat ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0/$file | awk -F'\t' '{print NF}' |sort|uniq|wc|awk '{print $1}'`
      if [ ${column_type} != 1 ]; then
          echo "column disagree! "
          exit 1
      fi
  done


 ## echo "RNAseqv2 files column matches..."
 ## select yn in "yes" "no"; do
 ##     case $yn in
 ##         yes) break;;
 ##         no ) exit 1 ;;
 ##     esac
 ## done
 

    for file in `ls ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0 | grep -i ${TUMOR}`; do
        column_no=`cat ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0/$file | awk -F'\t' '{print NF}' |head -n 1|awk '{print $1}'`
   
        echo "column_no is ${column_no} ..."
        ##select yn in "yes" "no"; do
        ##    case $yn in
        ##        yes) break;;
        ##        no ) exit 1 ;;
        ##    esac
        ##done
  
    done
  
  
  
  FILE=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0/${TUMOR}.rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.data.txt
   
  
  
  
   iquery -anq "remove(TCGA_RNAseq_LOAD_BUF)"    > /dev/null 2>&1
    
    
    
    iquery -anq "create temp array TCGA_RNAseq_LOAD_BUF
    <expression:string null>
    [source_instance_id = 0:*,1,0,
     chunk_number       = 0:*,1,0,
     line_number        = 0:*,1000,0,
     col_number         = 0:$((column_no)), $((column_no+1)), 0]"
    
    
  echo ${column_no} 
    
   ##iquery -aq "store(parse(split('$FILE', 'lines_per_chunk=1000'), 'chunk_size=1000','num_attributes=${column_no}'), temp1)" 
  
  
  
    iquery -anq "
    store(
     parse(
      split('$FILE', 'header=0', 'lines_per_chunk=1000'),
      'chunk_size=1000', 'split_on_dimension=1', 'num_attributes=$((column_no))'
     ),
     TCGA_RNAseq_LOAD_BUF
    )" 
   



echo "loading temp array completed..."
echo " continue to manipulate the LOAD_BUF..."
   select yn in "yes" "no"; do
      case $yn in
          yes) break;;
          no ) exit 1 ;;
      esac
  done
 

between(TCGA_RNAseq_LOAD_BUF,null, null, null, 0, null, null, null,0) 
##iquery -anq "remove(temp1)"
##
##  iquery -anq "create temp array temp1
##  <expression:string null>
##  [
##   chunk_number       = 0:*,1,0,
##   line_number        = 0:*,1000,0,
##   col_number         = 0:$((column_no)), $((column_no+1)), 0]"
## 
##iquery -anq "store(redimension(TCGA_RNAseq_LOAD_BUF, temp1), temp1)"

echo "redimesnion worked? ..."

select yn in "yes" "no"; do
    case $yn in 
        yes) break;;
        no ) exit 1;;
    esac
done 
 

iquery -anq "between(temp1, null, null, null, 1, null, null, null, ${column_no}"





 
  #Insert new patients
  
  echo "so far so good. Insert new patients to TCGA_${DATE}_PATIENT_STD ?"
  select yn in "yes" "no"; do
      case $yn in
          yes) break;;
          no ) exit 1 ;;
      esac
  done
  
  
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
              TCGA_RNAseq_LOAD_BUF,
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
  
 

echo "sfsg. insert new genes in TCGA_${DATE}_GENE_STD ?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1 ;;
    esac
done


#Insert new gene entries we havent seen before
#Me thinks we need a new gene list
#Lord this is messy
##  iquery -anq "
##  insert(
##   redimension(
##     apply(
##      cross_join(
##       uniq(
##        sort(
##         project(
##          filter(
##           index_lookup(
##             TCGA_RNAseq_LOAD_BUF,
##             redimension(TCGA_${DATE}_GENE_STD, <gene_symbol:string> [gene_id=0:*,1000000,0]) as B,
##             gene_, 
##             gid
##           ),
##           gid is null
##          ),
##          gene_
##         )
##        )
##       ) as new_genes,
##       aggregate( apply(TCGA_${DATE}_GENE_STD, gid, gene_id), max(gid) as mgid)
##      ),
##      gene_symbol, gene_,
##      gene_id, iif(mgid is null, new_genes.i, mgid+1+new_genes.i),
##      genomic_start, uint64( 0),
##      genomic_end,   uint64( 0),
##      strand,        char('0'),
##      locus_tag,     '-',
##      synonyms,      '-',
##      dbXrefs,       '-',
##      map_location,  '-',
##      description,   '-',
##      type_of_gene,  'unknown',
##      chromosome_nbr, uint64(0)
##     ),
##    TCGA_${DATE}_GENE_STD
##   ),
##   TCGA_${DATE}_GENE_STD
##  )"
##  
##  echo "sfsg. insert new samples in TCGA_${DATE}_SAMPLE_STD ?"
##  select yn in "yes" "no"; do
##      case $yn in
##          yes) break;;
##          no ) exit 1 ;;
##      esac
## done


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
              TCGA_RNAseq_LOAD_BUF,
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


echo "sfsg. insert new mutations in TCGA_${DATE}_RNAseq_STD ?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1 ;;
    esac
done


iquery -anq "
insert(
 redimension(
  apply(
   index_lookup(
    index_lookup(
     index_lookup(
      apply(
       TCGA_RNAseq_LOAD_BUF,
       sample_name, substr(sample_, 0, 15),
       GRCh_release, release_,
       mutation_genomic_chr, chrom_,
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
        zeros,gene_symbol
    ),

    A.gene_,
    gene_id_
   ),
   gene_id, iif(gene_id_ is null, 0, gene_id_)
  ),
  TCGA_${DATE}_RNAseq_STD
 ),
 TCGA_${DATE}_RNAseq_STD
)"

##echo "all done? clear the loading buffer?"
##select yn in "yes" "no"; do
##    case $yn in
##        yes) break;;
##        no ) exit 1 ;;
##    esac
##done


 
iquery -anq "remove(TCGA_RNAseq_LOAD_BUF)"    > /dev/null 2>&1
