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

#### wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein_normalization__data.Level_3.2015060100.0.0.tar.gz
{
wget -nv -P ${path_downloaded}  http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein_normalization__data.Level_3.${DATE_SHORT}00.0.0.tar.gz


} ||{
echo "This file does not exist:"
echo http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein_normalization__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
echo "exiting ..."
exit 1
}

tar -zxvf ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein_normalization__data.Level_3.${DATE_SHORT}00.0.0.tar.gz  --directory ${path_downloaded}/

  ##  create intermediate tsv files for easy loading  ##
  
proteinFile_original=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein_normalization__data.Level_3.${DATE_SHORT}00.0.0/${TUMOR}.protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein_normalization__data.data.txt
  
proteinFile=${proteinFile_original}
protein_probeFile=${cwd}/protein_probe.tsv
samplesFile=${cwd}/samples.tsv
unsorted_sampleFile=${cwd}/usamples.tsv

protein_geneFile=${cwd}/genes.tsv

new_geneFile=$3/gene_symbol_as_id.tsv

# write ${protein_probeFile}
python ${cwd}/protein_parser.py ${proteinFile_original} ${new_geneFile} ${cwd}

 
# output must be one line per sample for 'input' operator to work, thus OFS='\n'
cat ${proteinFile} |head -1|awk -F'\t' -v OFS='\n' '{ for (i=2; i<=NF;i++)  print $i}'|sort|uniq > ${samplesFile} 
cat ${proteinFile} |head -1|awk -F'\t' -v OFS='\n' '{ for (i=2; i<=NF;i++)  print $i}' > ${unsorted_sampleFile} 

cat ${protein_probeFile}|awk 'NR>1'|awk -F'\t' -v OFS='\n' '{print $3}'|sort|uniq > ${protein_geneFile}
 

## update patient array ##

#- insert new patients -#

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
              redimension(TCGA_${DATE}_SAMPLE_TYPE_STD, <code:string> [sample_type_id=0:*,1,0]),
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
                    '${protein_geneFile}',0,'tsv'
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


## build the probe array first (the probe index is needed for the construct data array) ##
probe_file=${protein_probeFile}
chunk_size=1000


iquery -anq "remove(TCGA_PROBE_LOAD_BUF)"    > /dev/null 2>&1
iquery -anq "create temp array TCGA_PROBE_LOAD_BUF
<probe_name:string null,
 gene_symbol:string null,
 reference_gene_symbols:string null,
 error: string null>
[source_instance_id = 0:*,1,0,
 chunk_number       = 0:*,1,0,
 line_number        = 0:*,${chunk_size},0]"

iquery -anq "
store(
  parse(
    split('${probe_file}','header=1',  'lines_per_chunk=${chunk_size}'),
    'chunk_size=${chunk_size}', 'num_attributes=3'),
  TCGA_PROBE_LOAD_BUF)"



# update protein_probe_index

iquery -anq "
insert(
  substitute(
    redimension(
      apply(
        cross_join(
          filter(
            index_lookup(
              uniq(sort(
                project(
                  TCGA_PROBE_LOAD_BUF,
                  probe_name
                  )
                )) as LB,
              substitute(
                redimension(
                  TCGA_${DATE}_PROTEIN_EXP_PROBE_STD,
                  <probe_name:string null>
                  [illuninahiseq_proteinseq_probe_id=0:*, 1000000,0]
                  ),
                build(<subval:string>[i=0:0,1,0], '_')
                ) as B,
              LB.probe_name,
              probeID
              ),
            probeID is null
            ) as new_probes,
    
          aggregate(
            apply(
              substitute(    
                redimension(  /* recreate B */
                  TCGA_${DATE}_PROTEIN_EXP_PROBE_STD,
                  <probe_name:string null>
                  [illuninahiseq_proteinseq_probe_id=0:*, 1000000,0]
                  ),
                build(<subval:string>[i=0:0,1,0], '_')
                ), /* end of B */
              pid,
              illuninahiseq_proteinseq_probe_id),
            max(pid) as mpid
            )
          ),
        probe_id, iif(mpid is null, new_probes.i, mpid + 1 + new_probes.i)
        ),
      <probe_name:string null>
      [probe_id=0:*,1000000,0]
      ),
    build(<subval:string>[i=0:0,1,0], '_')
    ),
  protein_probe_index
  )"


MAX_VERSION=`iquery -ocsv -aq "aggregate(versions(protein_probe_index), max(version_id))"|tail -n 1`
iquery -anq "remove_versions(protein_probe_index, $MAX_VERSION)"



iquery -anq "
insert(
  redimension(
    apply(
      index_lookup(
        index_lookup(
          TCGA_PROBE_LOAD_BUF as BF,
          protein_probe_index,
          BF.probe_name,
          probe_id
          ),
        redimension(
          substitute(
            TCGA_${DATE}_GENE_STD,
            build(<subVal:string>[i=0:0,1,0],'_'),
            gene_symbol
            ),
          <gene_symbol:string>[gene_id=0:*,1000000,0]
          ),
  
        reference_gene_symbols,
        gene_id
        ),
      reference_chromosome, '0',
      genomic_start, 0,
      genomic_end, 0,
      protein_exp_probe_id, probe_id
      ),
    TCGA_${DATE}_PROTEIN_EXP_PROBE_STD
    ),
  TCGA_${DATE}_PROTEIN_EXP_PROBE_STD
  )" 


MAX_VERSION=`iquery -ocsv -aq "aggregate(versions(TCGA_${DATE}_PROTEIN_EXP_PROBE_STD), max(version_id))"|tail -n 1`
iquery -anq "remove_versions(TCGA_${DATE}_PROTEIN_EXP_PROBE_STD, $MAX_VERSION)"


column_no=`cat ${proteinFile}|awk -F'\t' '{print NF}' |head -n 1|awk '{print $1}'`
     
echo "column_no is ${column_no} ..."
   
   
 
iquery -anq "remove(TCGA_protein_LOAD_BUF)" > /dev/null 2>&1
  
iquery -anq "create temp array TCGA_protein_LOAD_BUF
<expression:string null>
[source_instance_id = 0:*,1,0,
 chunk_number       = 0:*,1,0,
 line_number        = 0:*,1000,0,
 col_number         = 0:$((column_no)), $((column_no+1)), 0]"


CHUNK_SIZE=1000

iquery -anq "
store(
 parse(
  split('${proteinFile}', 'header=2', 'lines_per_chunk=${CHUNK_SIZE}'),
  'chunk_size=${CHUNK_SIZE}', 'split_on_dimension=1', 'num_attributes=$((column_no))'
 ),
 TCGA_protein_LOAD_BUF
)" 


  
iquery -anq "
insert(
  redimension(
    index_lookup(
      index_lookup(
        apply(
          index_lookup(
            cross_join(
              cross_join(
                between(
                  TCGA_protein_LOAD_BUF,
                  null, null, null, 1, null, null, null,$((column_no-1))
                  ) as MA,
                input(<sample_barcode:string>[sampleID=0:*,1000,0],
                      '${unsorted_sampleFile}', 0, 'tsv') as S,
                MA.col_number, S.sampleID
                ),
              between(
                TCGA_protein_LOAD_BUF,
                  null, null, null, 0, null, null, null,0
                ) as G,
              MA.line_number, G.line_number,
              MA.source_instance_id, G.source_instance_id,
              MA.chunk_number, G.chunk_number
              ),
            protein_probe_index,
            G.expression,
            protein_exp_probe_id
            ),
          ttn, '${TUMOR}',
          sample_name, sample_barcode,
          value, dcast(MA.expression, double(null))
          ) as H,
        project(
          TCGA_${DATE}_TUMOR_TYPE_STD,
          tumor_type_name),
        ttn,
        tumor_type_id
        ),
      redimension(
        TCGA_${DATE}_SAMPLE_STD,
        <sample_name:string>[sample_id=0:*,1000,0]),
      H.sample_name,
      sample_id
      ),
    TCGA_${DATE}_PROTEIN_EXP_STD
    ),
  TCGA_${DATE}_PROTEIN_EXP_STD
  )
"

MAX_VERSION=`iquery -ocsv -aq "aggregate(versions(TCGA_${DATE}_PROTEIN_EXP_STD), max(version_id))"|tail -n 1`
iquery -anq "remove_versions(TCGA_${DATE}_PROTEIN_EXP_STD, $MAX_VERSION)"


iquery -anq "remove(TCGA_PROBE_LOAD_BUF)"    > /dev/null 2>&1
iquery -anq "remove(TCGA_protein_LOAD_BUF)"    > /dev/null 2>&1
rm -rf  ${path_downloaded}
rm ${samplesFile}
rm ${unsorted_sampleFile}
rm ${protein_geneFile}

rm ${protein_probeFile}
