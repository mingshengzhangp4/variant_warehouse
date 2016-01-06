#!/bin/bash

if [ $# -ne 4 ]; then
 echo "Need 4 arguments:"
 echo "1. Date, such as 2015_06_01"
 echo "2. Tumor, such as ACC"
 echo "3. Script_path, such as /home/scidb/variant_warehouse/load_tcga/tcga_dev"
 echo "4. gene_file, such as /home/scidb/variant_warehouse/load_gene_37/tcga_python_pipe/newGene.tsv"
 exit 1
fi

DATE=$1
TUMOR=$2
cwd=$3
gene_file=$4

DATE_SHORT=`echo $DATE | sed  "s/_//g"`
echo $DATE_SHORT


path_downloaded=${cwd}/tcga_download

rm -rf ${path_downloaded}


mkdir -p ${path_downloaded}

# using non-normalized data Oct 23, 2015, per Manna request
####  gdac.broadinstitute.org_UVM.Mutation_Packager_Calls.Level_3.2015060100.0.0.tar.gz
#### wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes__data.Level_3.2015060100.0.0.tar.gz


{
wget -nv -P ${path_downloaded}  http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
} ||{
echo "This file does not exist:"
echo http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
echo "exiting ..."
exit 1
}

  tar -zxvf ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes__data.Level_3.${DATE_SHORT}00.0.0.tar.gz --directory ${path_downloaded}/


  ##  create intermediate tsv files for easy loading  ##
  
RNAseqFile_original=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes__data.Level_3.${DATE_SHORT}00.0.0/${TUMOR}.rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes__data.data.txt
  
RNAseqFile_raw_count=${cwd}/RNAseq_data_raw_count.tsv
RNAseqFile_scaled_estimate=${cwd}/RNAseq_data_scaled_estimate.tsv
samplesFile=${cwd}/samples.tsv
unsorted_sampleFile=${cwd}/usamples.tsv

RNAseq_geneFile=${cwd}/genes.tsv


# write ${RNAseqFile_raw_count}, ${RNAseqFile_scaled_estimate}
python ${cwd}/RNAseq_parser_raw.py ${RNAseqFile_original} ${gene_file} ${cwd}

 
# output must be one line per sample for 'input' operator to work, thus OFS='\n'
cat ${RNAseqFile_raw_count} |head -1|awk -F'\t' -v OFS='\n' '{ for (i=2; i<=NF;i++)  print $i}'|sort|uniq > ${samplesFile} 
cat ${RNAseqFile_raw_count} |head -1|awk -F'\t' -v OFS='\n' '{ for (i=2; i<=NF;i++)  print $i}' > ${unsorted_sampleFile} 

cat ${RNAseqFile_raw_count}|awk 'NR>2'|awk -F'\t' -v OFS='\n' '{print $1}'|sort|uniq > ${RNAseq_geneFile}
 
## update patient array ##

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
                    uniq(
                      sort(
                        project(
                          apply(
                            input(
                              <sample_name:string> [sampleID=0:*,1000,0],
                              '${samplesFile}', 0, 'tsv'
                              ),
                            patient_name,
                            substr(sample_name, 0, 12)
                            ),
                          patient_name)
                        )
                      ) as A,
                      redimension(
                        TCGA_${DATE}_PATIENT_STD,
                        <patient_name:string>[patient_id=0:*,1000,0]
                      ) as B,
                    A.patient_name,
                    pat_index
                    ),
                  pat_index is null
                  ),
                patient_name
                )
              )
            ) as new_patients,
          aggregate(
            apply(
              TCGA_${DATE}_PATIENT_STD,
              pid,
              patient_id
              ),
            max(pid) as mpid
            )
          ),
        ttn, '${TUMOR}',
        patient_id, iif(mpid is null, new_patients.i, mpid+1+new_patients.i)
        ),
      project(
        TCGA_${DATE}_TUMOR_TYPE_STD,
        tumor_type_name),
      ttn,
      tumor_type_id
      ),
    TCGA_${DATE}_PATIENT_STD
    ),
  TCGA_${DATE}_PATIENT_STD
  )"  

#- then add patient with new tumor-type -#
iquery -anq "
  insert(
    redimension(
      index_lookup(
        index_lookup(
          apply(  
            input(
               <sample_name:string> [sampleID=0:*,1000,0],
               '${samplesFile}', 0, 'tsv'
               ),
            patient_name,
            substr(sample_name, 0,12),
            ttn,
            '${TUMOR}'
            ) as D,
          project(
            TCGA_${DATE}_TUMOR_TYPE_STD,
            tumor_type_name),
          ttn,
          tumor_type_id
          ),
        redimension(TCGA_${DATE}_PATIENT_STD,
          <patient_name:string>
          [patient_id=0:*, 1000, 0]),
        D.patient_name,
        patient_id
        ),
      TCGA_${DATE}_PATIENT_STD
      ),
    TCGA_${DATE}_PATIENT_STD
    )
    "


MAX_VERSION=`iquery -ocsv -aq "aggregate(versions(TCGA_${DATE}_PATIENT_STD), max(version_id))"|tail -n 1`
iquery -anq "remove_versions(TCGA_${DATE}_PATIENT_STD, $MAX_VERSION)"


# update sample array #
iquery -anq"
insert(
  redimension(
    index_lookup(
      apply(
        index_lookup(
          index_lookup(
            apply(
              apply(
                cross_join(
                  uniq(sort(
                    project(               
                      filter(
                        index_lookup(
                          apply(
                            input(
                              <sample_barcode:string> [sampleID=0:*,1000,0],
                              '${samplesFile}', 0, 'tsv'
                              ),
                            sample_name,
                            sample_barcode
                            ) as B,
  
                          redimension(
                            TCGA_${DATE}_SAMPLE_STD,
                            <sample_name:string>[sample_id = 0:*,1000,0]
                            ) as C,
  
                          B.sample_name,
                          sample_id
                          ),
                        sample_id is null
                        ),
                      sample_name
                      )
                    )) as new_samples,
                  aggregate(
                    apply(
                      TCGA_${DATE}_SAMPLE_STD, sample_index, sample_id),
                    max(sample_index) as max_sid
                    )
                  ),
                sample_id, iif(max_sid is null, new_samples.i, max_sid+1+new_samples.i)
                ),
                ttn, '${TUMOR}',
                sample_code, substr(sample_name,13,2)
                ) as D,
              redimension(TCGA_${DATE}_SAMPLE_TYPE_STD, <code:string> [sample_type_id=0:*,1000,0]),
              D.sample_code,
              sample_type_id
              ),
            project(             
              TCGA_${DATE}_TUMOR_TYPE_STD,
              tumor_type_name),
            D.ttn,
            tumor_type_id
            ),
          patient_name,
          substr(sample_name, 0,12)
          ) as E,
        redimension(
          TCGA_${DATE}_PATIENT_STD,
          <patient_name:string>[patient_id=0:*,1000,0]
          ),
        E.patient_name,
        patient_id
        ),
      TCGA_${DATE}_SAMPLE_STD
    ),
  TCGA_${DATE}_SAMPLE_STD
  )"
    
# then sample with new tumor type #
iquery -anq "  
  insert(
    redimension(  
      index_lookup(
        index_lookup(  
          index_lookup(  
            index_lookup(
              apply(
                input(
                  <sample_barcode:string> [sampleID=0:*,1000,0],
                  '${samplesFile}', 0, 'tsv'
                  ),
                patient_name,
                substr(sample_barcode, 0, 12),
                sample_name,
                sample_barcode,
                sample_code,
                substr(sample_barcode, 13, 2),
                ttn,
                '${TUMOR}'
                ) as A,
              redimension(TCGA_${DATE}_PATIENT_STD,
                <patient_name:string>[patient_id=0:*,1000,0]
                ),
              A.patient_name,
              patient_id
              ),
            redimension(TCGA_${DATE}_SAMPLE_STD,
              <sample_name:string>[sample_id=0:*,1000,0]
              ),
            A.sample_name,
            sample_id
            ),
          redimension(TCGA_${DATE}_SAMPLE_TYPE_STD,
            <code:string>[sample_type_id=0:*,1000,0]
            ),
          A.sample_code,
          sample_type_id
          ),
        redimension(TCGA_${DATE}_TUMOR_TYPE_STD,
          <tumor_type_name:string>[tumor_type_id=0:*, 1000,0]
          ),
        A.ttn,
        tumor_type_id
        ),
      TCGA_${DATE}_SAMPLE_STD
      ),
    TCGA_${DATE}_SAMPLE_STD
    )
  "


MAX_VERSION=`iquery -ocsv -aq "aggregate(versions(TCGA_${DATE}_SAMPLE_STD), max(version_id))"|tail -n 1`
iquery -anq "remove_versions(TCGA_${DATE}_SAMPLE_STD, $MAX_VERSION)"

##  update gene list ##
iquery -anq "
insert(
  redimension(
    apply(
      apply(
        cross_join(
          uniq(sort(
            project(
              filter(
                index_lookup(
                  input(
                    <gene_symbol:string>[gene_id=0:*,1000000,0], 
                    '${RNAseq_geneFile}',0,'tsv'
                    ) as A,
                  redimension(
                    substitute(
                      TCGA_${DATE}_GENE_STD,
                      build(<subVal:string>[i=0:0,1,0],'_'),
                      gene_symbol
                      ),
                    <gene_symbol:string>[gene_id=0:*,1000000,0]
                    ),
                  A.gene_symbol,
                  EID
                  ),
                EID is null
                ),
              gene_symbol
              )
            )) as new_gene,
            aggregate(
              apply(
                TCGA_${DATE}_GENE_STD,
                gene_index,
                gene_id
                ),
              max(gene_index) as mgid
              )
          ),
          gene_id, iif(mgid is null, new_gene.i, mgid+1+new_gene.i)
        ),
      entrez_geneID, '_', start_, '_', end_, '_',
      strand_,'_', hgnc_synonym, '_',synonym,'_',
      dbXrefs,'_', cyto_band,'_', full_name,'_', 
      type_of_gene,'_', chrom,'_', other_locations,'_'
      ),
    TCGA_${DATE}_GENE_STD
    ),
TCGA_${DATE}_GENE_STD)"


MAX_VERSION=`iquery -ocsv -aq "aggregate(versions(TCGA_${DATE}_GENE_STD), max(version_id))"|tail -n 1`
iquery -anq "remove_versions(TCGA_${DATE}_GENE_STD, $MAX_VERSION)"


column_no=`cat ${RNAseqFile_raw_count}|awk -F'\t' '{print NF}' |head -n 1|awk '{print $1}'`
     
echo "column_no is ${column_no} ..."
   
   
 
iquery -anq "remove(TCGA_RNAseq_raw_count_LOAD_BUF)" > /dev/null 2>&1
  
iquery -anq "create temp array TCGA_RNAseq_raw_count_LOAD_BUF
<expression:string null>
[source_instance_id = 0:*,1,0,
 chunk_number       = 0:*,1,0,
 line_number        = 0:*,1000,0,
 col_number         = 0:$((column_no)), $((column_no+1)), 0]"


CHUNK_SIZE=1000

iquery -anq "
store(
 parse(
  split('${RNAseqFile_raw_count}', 'header=2', 'lines_per_chunk=${CHUNK_SIZE}'),
  'chunk_size=${CHUNK_SIZE}', 'split_on_dimension=1', 'num_attributes=$((column_no))'
 ),
 TCGA_RNAseq_raw_count_LOAD_BUF
)" 
   

column_no=`cat ${RNAseqFile_scaled_estimate}|awk -F'\t' '{print NF}' |head -n 1|awk '{print $1}'`
     
echo "column_no is ${column_no} ..."
   
   
 
iquery -anq "remove(TCGA_RNAseq_scaled_estimate_LOAD_BUF)" > /dev/null 2>&1
  
iquery -anq "create temp array TCGA_RNAseq_scaled_estimate_LOAD_BUF
<expression:string null>
[source_instance_id = 0:*,1,0,
 chunk_number       = 0:*,1,0,
 line_number        = 0:*,1000,0,
 col_number         = 0:$((column_no)), $((column_no+1)), 0]"


CHUNK_SIZE=1000

iquery -anq "
store(
 parse(
  split('${RNAseqFile_scaled_estimate}', 'header=2', 'lines_per_chunk=${CHUNK_SIZE}'),
  'chunk_size=${CHUNK_SIZE}', 'split_on_dimension=1', 'num_attributes=$((column_no))'
 ),
 TCGA_RNAseq_scaled_estimate_LOAD_BUF
)" 


iquery -anq "remove(TCGA_TMP)" > /dev/null 2>&1
iquery -anq "create array TCGA_TMP
 <RNA_expressionLevel:double null>
 [tumor_type_id=0:*,1,0,
  sample_id=0:*,1000,0,
  gene_id=0:*,1000000,0]"


## loading RNAseq data in one step; for two steps, see what follows ##
iquery -anq "
insert(
  cast(
    cross_join(
      redimension(
        index_lookup(
          index_lookup(
            index_lookup(
              apply(
                cross_join(
                  cross_join(
                    between(
                      TCGA_RNAseq_raw_count_LOAD_BUF,
                      null, null, null, 1, null, null, null,$((column_no-1))
                      ) as MA,
                    input(<sample_barcode:string>[sampleID=0:*,1000,0],
                          '${unsorted_sampleFile}', 0, 'tsv') as S,
                    MA.col_number, S.sampleID
                    ),
                  
                  between(
                    TCGA_RNAseq_raw_count_LOAD_BUF,
                      null, null, null, 0, null, null, null,0
                    ) as G,
                
                  MA.line_number, G.line_number,
                  MA.source_instance_id, G.source_instance_id,
                  MA.chunk_number, G.chunk_number
                  ),
                ttn, '${TUMOR}',
                sample_name, S.sample_barcode,
                gene_symbol, G.expression,
                RNA_expressionLevel, dcast(MA.expression,double(null))
                ) as Q,
              project(
                TCGA_${DATE}_TUMOR_TYPE_STD,
                tumor_type_name),
              ttn,
              tumor_type_id
              ),
            redimension(
              TCGA_${DATE}_SAMPLE_STD,
              <sample_name:string>[sample_id=0:*,1000,0]
              ),
            Q.sample_name,
            sample_id
            ),
           redimension(
             substitute(
               TCGA_${DATE}_GENE_STD,
               build(<subVal:string>[i=0:0,1,0],'_'),
               gene_symbol
               ),
            <gene_symbol:string>[gene_id=0:*,1000000,0]
            ),
          Q.gene_symbol,
          gene_id
          ),
        TCGA_TMP
        ) as RAW,
    
      redimension(
        index_lookup(
          index_lookup(
            index_lookup(
              apply(
                cross_join(
                  cross_join(
                    between(
                      TCGA_RNAseq_scaled_estimate_LOAD_BUF,
                      null, null, null, 1, null, null, null,$((column_no-1))
                      ) as MA,
                    input(<sample_barcode:string>[sampleID=0:*,1000,0],
                          '${unsorted_sampleFile}', 0, 'tsv') as S,
                    MA.col_number, S.sampleID
                    ),
                  
                  between(
                    TCGA_RNAseq_scaled_estimate_LOAD_BUF,
                      null, null, null, 0, null, null, null,0
                    ) as G,
                
                  MA.line_number, G.line_number,
                  MA.source_instance_id, G.source_instance_id,
                  MA.chunk_number, G.chunk_number
                  ),
                ttn, '${TUMOR}',
                sample_name, S.sample_barcode,
                gene_symbol, G.expression,
                RNA_expressionLevel, dcast(MA.expression,double(null))
                ) as Q,
              project(
                TCGA_${DATE}_TUMOR_TYPE_STD,
                tumor_type_name),
              ttn,
              tumor_type_id
              ),
            redimension(
              TCGA_${DATE}_SAMPLE_STD,
              <sample_name:string>[sample_id=0:*,1000,0]
              ),
            Q.sample_name,
            sample_id
            ),
           redimension(
             substitute(
               TCGA_${DATE}_GENE_STD,
               build(<subVal:string>[i=0:0,1,0],'_'),
               gene_symbol
               ),
            <gene_symbol:string>[gene_id=0:*,1000000,0]
            ),
          Q.gene_symbol,
          gene_id
          ),
        TCGA_TMP
        ) as SCALE,
      RAW.tumor_type_id, SCALE.tumor_type_id,
      RAW.sample_id, SCALE.sample_id,
      RAW.gene_id, SCALE.gene_id
      ),
    TCGA_${DATE}_RNAseq_STD
    ), 
  TCGA_${DATE}_RNAseq_STD)
"

MAX_VERSION=`iquery -ocsv -aq "aggregate(versions(TCGA_${DATE}_RNAseq_STD), max(version_id))"|tail -n 1`
iquery -anq "remove_versions(TCGA_${DATE}_RNAseq_STD, $MAX_VERSION)"


iquery -anq "remove(TCGA_RNAseq_raw_count_LOAD_BUF)"    > /dev/null 2>&1
iquery -anq "remove(TCGA_RNAseq_scaled_estimate_LOAD_BUF)"    > /dev/null 2>&1
rm -rf  ${path_downloaded}
rm ${RNAseqFile_raw_count}
rm ${RNAseqFile_scaled_estimate}
rm ${samplesFile}
rm ${unsorted_sampleFile}
rm ${RNAseq_geneFile}


