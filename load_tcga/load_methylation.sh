#!/bin/bash

if [ $# -ne 3 ]; then
 echo "Need 3 arguments:"
 echo "1. Date, such as 2015_06_01"
 echo "2. Tumor, such as ACC"
 echo "3. Script_path, such as /home/mzhang/Paradigm4_labs/variant_warehouse/load_tcga/tcga_dev"
 exit 1
fi

DATE=$1
TUMOR=$2
cwd=$3

DATE_SHORT=`echo $DATE | sed  "s/_//g"`
echo $DATE_SHORT


path_downloaded=${cwd}/tcga_download

rm -rf ${path_downloaded}

mkdir -p ${path_downloaded}

#### wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.2015060100.0.0.tar.gz


{
wget -nv  -P ${path_downloaded}  http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
} ||{
echo "This file does not exist:"
echo http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
echo "exiting ..."
exit 1
}

tar -zxvf ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.${DATE_SHORT}00.0.0.tar.gz --directory ${path_downloaded}/


  ##  create intermediate tsv files for easy loading  ##

input_path=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.${DATE_SHORT}00.0.0
methyl_file=${TUMOR}.methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.data.txt
input_file=${input_path}/${methyl_file}
python methylation_file_parser.py ${input_file}


## update patient array ##
 
sampleBarCodeFile=${cwd}/methyl_sample_barcodes.txt
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
                              <sample_barcode:string> [sampleID=0:*,1000,0],
                              '${sampleBarCodeFile}', 0, 'tsv'
                              ),
                            patient_name,
                            substr(sample_barcode, 0, 12)
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
                            substr(sample_barcode, 0,16)
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
    

## update gene array ##
geneFile=${cwd}/methyl_genes.txt
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
                    input(
                    <gene_:string>[gene_id=0:*,1000000,0], 
                    '${geneFile}',0,'tsv'
                    ) as A,

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


## build the probe array first (the probe index is needed for the construct methyl data array) ##

probe_file=${cwd}/methyl_probe_data.txt
iquery -anq "remove(TCGA_PROBE_LOAD_BUF)"    > /dev/null 2>&1
chunk_size=1000
iquery -anq "create temp array TCGA_PROBE_LOAD_BUF
<probe_name:string null,
 gene_symbol:string null,
 reference_chromosome:string null,
 genomic_start_:string null,
 genomic_end_:string null,
 reference_gene_symbols:string null,
 error: string null>
[source_instance_id = 0:*,1,0,
 chunk_number       = 0:*,1,0,
 line_number        = 0:*,${chunk_size},0]"

iquery -anq "
store(
  parse(
    split('${probe_file}', 'lines_per_chunk=${chunk_size}'),
    'chunk_size=${chunk_size}', 'num_attributes=6'),
  TCGA_PROBE_LOAD_BUF)"

## iquery -anq "remove(TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD)"
## iquery -anq "create array
## TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD
## <probe_name:string null,
## reference_chromosome:string null,
## genomic_start:int64 null,
## genomic_end:int64 null,
## reference_gene_symbols:string null>
## [gene_id=0:*,1000000,0,
## humanmethylation450_probe_id=0:*,1000,0]"


iquery -anq "
store(
  redimension(
    apply(
      index_lookup(
        index_lookup(
          TCGA_PROBE_LOAD_BUF,
          substitute(
            redimension(
              TCGA_${DATE}_GENE_STD,
              <gene_symbol:string null>
              [gene_id=0:*, 1000000,0]
              ),
            build(<subval:string>[i=0:0,1,0],'_'),
            gene_symbol
            ),
          TCGA_PROBE_LOAD_BUF.gene_symbol,
          gene_index) as A,
        substitute(
          uniq(sort(
            project(TCGA_PROBE_LOAD_BUF,
            probe_name
              )
            )),
          build(<subval:string>[i=0:0,1,0], '_')
          ),
        A.probe_name,
        probe_index
      ),
      gene_id, gene_index,
      humanmethylation450_probe_id, probe_index,
      genomic_start, dcast(genomic_start_, int64(null)),
      genomic_end, dcast(genomic_end_, int64(null))
      ),
    TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD
    ),
TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD
)"


## finally, build methylation data array proper ##
methyl_dataFile=${cwd}/methyl_data.txt
column_no=`cat ${methyl_dataFile}|awk -F'\t' '{print NF}' |head -n 1|awk '{print $1}'`
iquery -anq "remove(TCGA_METHYLATION_LOAD_BUF)"    > /dev/null 2>&1
  
iquery -anq "create temp array TCGA_METHYLATION_LOAD_BUF
<val:string null>
[source_instance_id = 0:*,1,0,
 chunk_number       = 0:*,1,0,
 line_number        = 0:*,1000,0,
 col_number         = 0:$((column_no)), $((column_no+1)), 0]"

# col_number = column_no + 1(for 'error' column)


iquery -anq "
store(
 parse(
  split('${methyl_dataFile}', 'header=0', 'lines_per_chunk=1000'),
  'chunk_size=1000', 'split_on_dimension=1', 'num_attributes=$((column_no))'
 ),
 TCGA_METHYLATION_LOAD_BUF
)" 


## iquery -anq "remove(TCGA_${DATE}_HUMANMETHYLATION450_STD)"
## 
## iquery -anq "create array
##  TCGA_${DATE}_HUMANMETHYLATION450_STD
##  <value:double null>
##  [tumor_type_id=0:*,1,0,
##   sample_id=0:*,1000,0,
##   humanmethylation450_probe_id=0:*,1000, 0]"

iquery -anq "
insert(cast(
  project(
    apply(
      redimension(
        project(
          index_lookup(
            apply(
              index_lookup(
                apply(
                  index_lookup(                         
                    cross_join(
                      between(
                        TCGA_METHYLATION_LOAD_BUF, 
                        null, null, null, 0, null, null, null,0
                        ) as probes,
                      cross_join(
                        between(
                         TCGA_METHYLATION_LOAD_BUF, 
                         null, null, null, 1, null, null, null,$((column_no-1))
                         ) as samples,
                        input(
                          <sample_barcode:string> [sampleID=0:*,1000,0],
                          '${sampleBarCodeFile}', 0, 'tsv'
                          ) as S,
                        samples.col_number, S.sampleID
                        ),
                      probes.source_instance_id, samples.source_instance_id,  
                      probes.chunk_number, samples.chunk_number,
                      probes.line_number, samples.line_number
                      ),
                    redimension(
                      substitute( 
                        apply(
                          project(
                            TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD,
                            probe_name
                            ),
                          probe_id, humanmethylation450_probe_id
                          ),
                        build(<subval:string>[i=0:0,1,0],'_'),
                        probe_name),
                      <probe_name:string>
                      [humanmethylation450_probe_id=0:*,1000,0]
                      ) as P,
                    probes.val, humanmethylation450_probe_id
                    ),
                  sample_name, substr(S.sample_barcode, 0,16)
                  ) as M,
                redimension(
                  TCGA_${DATE}_SAMPLE_STD,
                  <sample_name:string>[sample_id = 0:*,1000,0]
                  ),
                M.sample_name, sample_id
                ),
              tumor_type, '${TUMOR}'
              ),
            TCGA_${DATE}_TUMOR_TYPE_STD,
            tumor_type,
            tumor_type_id
            ),
          samples.val, sample_id,humanmethylation450_probe_id
          ),
        <val: string null>
        [tumor_type_id = 0:*,1,0,
         sample_id = 0:*,1000,0,
         humanmethylation450_probe_id=0:*,1000,0]
        ),
      val_NAreplaced, dcast(val, double(null))
      ),
    val_NAreplaced
    ),
  TCGA_${DATE}_HUMANMETHYLATION450_STD),TCGA_${DATE}_HUMANMETHYLATION450_STD)
"

iquery -anq "remove(TCGA_METHYLATION_LOAD_BUF)"    > /dev/null 2>&1
iquery -anq "remove(TCGA_PROBE_LOAD_BUF)"    > /dev/null 2>&1
rm -rf ${path_downloaded}
rm ${methyl_dataFile}
rm ${probe_file}
rm ${geneFile}
rm ${sampleBarCodeFile}
