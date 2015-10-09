#!/bin/bash

if [ $# -ne 2 ]; then
 echo "Need 2 arguments: date, tumor"
 exit 1
fi

DATE=$1
TUMOR=$2

DATE_SHORT=`echo $DATE | sed  "s/_//g"`
echo $DATE_SHORT

## iquery -anq "remove(TCGA_${DATE}_RNAseqV2_STD)"

cwd=`pwd`
path_downloaded=${cwd}/tcga_download
mkdir -p ${path_downloaded}

####  gdac.broadinstitute.org_UVM.Mutation_Packager_Calls.Level_3.2015060100.0.0.tar.gz
#### wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.2015060100.0.0.tar.gz


{
wget -nv -P ${path_downloaded}  http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
} ||{
echo "This file does not exist:"
echo http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
echo "exiting ..."
exit 1
}

  tar -zxvf ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0.tar.gz --directory ${path_downloaded}/


  ##  create intermediate tsv files for easy loading  ##
  
  RNAseqFile=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0/${TUMOR}.rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.data.txt
  
  samplesFile=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0/samples.tsv
  
  Entrez_samplesFile=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0/Entrez_samples.tsv
  
  Entrez_geneList=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0/Entrez_geneList.tsv
  
  RNAexpr=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0/RNAexpression.tsv
  
  
 # output must be one line per sample for 'input' operator to work, thus OFS='\n'
 cat ${RNAseqFile} |head -1|awk -F'\t' -v OFS='\n' '{ for (i=2; i<=NF;i++)  print $i}' > ${samplesFile} 
 
 cat ${RNAseqFile}|awk 'NR>2'|awk -F'|' '{ for (i=2; i<=NF; i++) print $i}' > ${Entrez_samplesFile}
 
 cat ${Entrez_samplesFile} |awk  '{for (i=2; i<NF; i++) printf $i "\t"; print $NF}' > ${RNAexpr} 
 
 cat ${Entrez_samplesFile} |awk -F'\t' -v OFS='\n' '{print $1}' > ${Entrez_geneList}


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
                    uniq(
                      sort(
                        redimension(
                          TCGA_${DATE}_PATIENT_STD,
                          <patient_name:string>[patient_id=0:*,1000,0]
                          )
                        )
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
      TCGA_${DATE}_TUMOR_TYPE_STD,
      ttn,
      tumor_type_id
      ),
    TCGA_${DATE}_PATIENT_STD
    ),
  TCGA_${DATE}_PATIENT_STD
  )"  


# update sample array #
iquery -anq"
insert(
  redimension(
    index_lookup(
      apply(
        index_lookup(
          apply(
            apply(
              cross_join(
                uniq(sort(
                  project(               
                    filter(
                      index_lookup(
                        input(
                          <sample_name:string> [sampleID=0:*,1000,0],
                          '${samplesFile}', 0, 'tsv'
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
              sample_type_id, 0
              ) as D,
            TCGA_${DATE}_TUMOR_TYPE_STD,
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
                    <entrez_geneID:int64>[gene_id=0:*,1000000,0], 
                    '${Entrez_geneList}',0,'tsv'
                    ) as A,
                  uniq(
                    sort(
                      redimension(
                        substitute(
                          TCGA_${DATE}_GENE_STD,
                          build(<subVal:int64>[i=0:0,1,0],0),
                          entrez_geneID
                          ),
                        <entrez_geneID:int64>[gene_id=0:*,1000000,0]
                        )
                      )
                    ) as B,
                  A.entrez_geneID,
                  EID
                  ),
                EID is null
                ),
              entrez_geneID
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
      gene_symbol, '_', start_, '_', end_, '_',
      strand_,'_', hgnc_synonym, '_',synonym,'_',
      dbXrefs,'_', cyto_band,'_', full_name,'_', 
      type_of_gene,'_', chrom,'_', other_locations,'_'
      ),
    TCGA_${DATE}_GENE_STD
    ),
TCGA_${DATE}_GENE_STD)"




      for file in `ls ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0 | grep -i ${TUMOR}`; do
          column_no=`cat ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.Level_3.${DATE_SHORT}00.0.0/$file | awk -F'\t' '{print NF}' |head -n 1|awk '{print $1}'`
     
          echo "column_no is ${column_no} ..."
   
      done
    
    
 
iquery -anq "remove(TCGA_RNAseq_LOAD_BUF)"    > /dev/null 2>&1
  
iquery -anq "create temp array TCGA_RNAseq_LOAD_BUF
<expression:string null>
[source_instance_id = 0:*,1,0,
 chunk_number       = 0:*,1,0,
 line_number        = 0:*,1000,0,
 col_number         = 0:$((column_no-1)), $((column_no)), 0]"




iquery -anq "
store(
 parse(
  split('${RNAexpr}', 'header=0', 'lines_per_chunk=1000'),
  'chunk_size=1000', 'split_on_dimension=1', 'num_attributes=$((column_no-1))'
 ),
 TCGA_RNAseq_LOAD_BUF
)" 
   

## loading RNAseq data in one step; for two steps, see what follows ##
iquery -anq "
insert(
  redimension(
    cast(
      substitute(
        project(
          index_lookup(
            index_lookup(
              apply(
                index_lookup(
                  apply(
                    cross_join(
                      cross_join(
                        between(
                          redimension(
                            apply(
                                TCGA_RNAseq_LOAD_BUF,
                                gene_id,
                                1000*chunk_number + line_number
                              ),
                            <expression:string null>
                            [col_number=0:*,1000000,0,
                             gene_id=0:*,1000,0]
                            ),
                          0, null, $((column_no-1)), null
                          ) as G,
                        input(
                          <sample_name:string null>
                          [sample_id=0:*, 1000000,0],
                          '${samplesFile}',
                          0,
                          'tsv'
                          ),
                        G.col_number,
                        sample_id
                        ) as U,
                      input(
                       <entrezID:string null>
                       [gene_id=0:*, 1000,0],
                       '${Entrez_geneList}',
                       0,
                       'tsv'
                       ) as N,
                      U.gene_id,
                      N.gene_id
                      ),
                    ttn, '${TUMOR}',
                    RNA_expressionLevel, dcast(expression, double(null))
                    ) as V,
                  TCGA_${DATE}_TUMOR_TYPE_STD,
                  V.ttn,
                  tumor_type_id) as W,
                entrez_geneID,
                dcast(W.entrezID, int64(null))
                ) as VW,
              substitute(
                project(TCGA_${DATE}_GENE_STD,entrez_geneID),
                build(<subVal:int64>[i=0:0,1,0],0),
                entrez_geneID
                ),
              VW.entrez_geneID,
              en_geneID
              ) as H,
            redimension(
              TCGA_${DATE}_SAMPLE_STD,
              <sample_name:string>[sample_id=0:*,1000000,0]
              ),
            H.sample_name,
            sample_id
            ),
          tumor_type_id,
          en_geneID,
          sample_id,
          RNA_expressionLevel
          ),
        build(<subVal:int64>[i=0:0,1,0], 0),
        tumor_type_id, en_geneID, sample_id
        ),
      <tumor_type_id: int64,
       gene_id: int64,
       sample_id: int64,
       RNA_expressionLevel:double null>
      [i=0:*,1000,0,
       j=0:*,1000,0]
      ),
    TCGA_${DATE}_RNAseqV2_STD
    ),
  TCGA_${DATE}_RNAseqV2_STD
  )"


iquery -anq "remove(TCGA_RNAseq_LOAD_BUF)"    > /dev/null 2>&1
rm -rf  ${path_downloaded}
