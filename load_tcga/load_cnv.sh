#!/bin/bash

if [ $# -ne 4 ]; then
 echo "Need 4 arguments:"
 echo "1. DATE, such as 2015_06_01"
 echo "2. TUMOR, such as ACC"
 echo "3. script_path, such as /home/mzhang/Paradigm4_labs/variant_warehouse/load_tcga/tcga_dev"
 echo "4. Gene_file, such as /home/mzhang/Paradigm4_labs/variant_warehouse/load_gene_37/newGenes.tsv"
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

#### wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.Level_3.2015060100.0.0.tar.gz

{
wget -nv -P ${path_downloaded}  http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.Level_3.${DATE_SHORT}00.0.0.tar.gz
} ||{
echo "This file does not exist:"
echo http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.Level_3.${DATE_SHORT}00.0.0.tar.gz
echo "exiting ..."
exit 1
}

tar -zxvf ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.Level_3.${DATE_SHORT}00.0.0.tar.gz --directory ${path_downloaded}/


  ##  create intermediate tsv files for easy loading  ##

input_path=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.Level_3.${DATE_SHORT}00.0.0

cnv_file=${TUMOR}.snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.seg.txt
input_file=${input_path}/${cnv_file}

# python parser takes cnv_file and creates ${cwd}/cnv_sample_barcodes.txt and ${cwd}/cnv_data.txt #
python cnv_file_parser.py ${input_file} ${gene_file} ${cwd}

## update patient array ##
sampleBarCodeFile=${cwd}/cnv_sample_barcodes.txt
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
     
## build the probe array first (the probe index is needed to construct cnv data array) ##

probe_data_file=${cwd}/cnv_data.txt

##  sample_barcode	probe_name	Mean_value	reference_gene_symbol	chromosome
##  TCGA-PK-A5HC-11A-11D-A309-01	LOC100506869	0.0018	LOC100506869	12
##  TCGA-PK-A5HC-11A-11D-A309-01	MTVR2	0.0009	MTVR2	17
##  TCGA-PK-A5HC-11A-11D-A309-01	LOC100506860	0.0046	LOC100506860	7
##  TCGA-PK-A5HC-11A-11D-A309-01	ATRX	0.0023	ATRX	23
##  TCGA-PK-A5HC-11A-11D-A309-01	LOC643634	0.0024	LOC643634	3


iquery -anq "remove(TCGA_PROBE_DATA_LOAD_BUF)"    > /dev/null 2>&1
chunk_size=1000
iquery -anq "create temp array TCGA_PROBE_DATA_LOAD_BUF
<sample_barcode: string null,
 probe_name:string null,
 Mean_value:string null,
 reference_gene_symbol:string null,
 chromosome:string null,
 error: string null>
[source_instance_id = 0:*,1,0,
 chunk_number       = 0:*,1,0,
 line_number        = 0:*,${chunk_size},0]"

iquery -anq "
store(
  parse(
    split('${probe_data_file}','header=1',  'lines_per_chunk=${chunk_size}'),
    'chunk_size=${chunk_size}', 'num_attributes=5'),
  TCGA_PROBE_DATA_LOAD_BUF)"


iquery -anq "
insert(
  redimension(
    apply(
      index_lookup(
      
        index_lookup(
          TCGA_PROBE_DATA_LOAD_BUF,
          substitute(
            redimension(TCGA_${DATE}_GENE_STD,
              <gene_symbol: string null>
              [gene_id = 0:*, 1000000,0]
              ),
            build(<subval:string>[i=0:0,1,0], '_'),
            gene_symbol
            ),
            reference_gene_symbol,
            gene_id
          ),
      
        redimension(
          apply(
            cross_join(
              uniq(sort(
                project(
                  filter(  -- get unmathed/new probe_name
                    index_lookup(  -- probe_name lookup
                      TCGA_PROBE_DATA_LOAD_BUF as L,
                      substitute(
                        redimension(
                          -- find index for probe_id
                          apply(
                          TCGA_${DATE}_GENOME_WIDE_SNP_6_PROBE_STD,
                          probe_index,
                          genome_wide_snp_6_probe_id
                          ),
                          <probe_name:string null>
                          [probe_index=0:*, 1000,0]
                          ),
                        build(<subval:string>[i=0:0,1,0], '_'),
                        probe_name
                        ),
                      L.probe_name,
                      probeID
                      ),  -- probe_name look_up
                    probeID is null
                    ),
                  probe_name
                  )
                )) as new_probes,
              
              aggregate(
                apply(
                  redimension(
                    TCGA_${DATE}_GENOME_WIDE_SNP_6_PROBE_STD,
                    <probe_name:string null>
                    [probe_index=0:*, 1000000,0]
                    ),
                  probID,
                  probe_index
                  ),
                max(probID) as mprobID
                )
            ),
            probe_id, iif(mprobID is null, new_probes.i, mprobID+1+new_probes.i)
            ),
          <probe_name: string>[probe_id=0:*,1000000,0]
          ) as new_probe_index,
      
         TCGA_PROBE_DATA_LOAD_BUF.probe_name,
         probe_index
         ),
    
      reference_chromosome, chromosome,
      genomic_start, 0,
      genomic_end, 0,
      reference_gene_symbols, reference_gene_symbol,
      genome_wide_snp_6_probe_id, probe_index 
      ),
    TCGA_${DATE}_GENOME_WIDE_SNP_6_PROBE_STD
    ),
  TCGA_${DATE}_GENOME_WIDE_SNP_6_PROBE_STD
  )"


iquery -anq "
insert(
  redimension(
    apply(
      index_lookup(
        apply(
          index_lookup(
            apply(
              index_lookup(
                TCGA_PROBE_DATA_LOAD_BUF,
                substitute(
                  redimension(
                    TCGA_${DATE}_GENOME_WIDE_SNP_6_PROBE_STD,
                    <probe_name:string null>
                    [genome_wide_snp_6_probe_id=0:*,1000000,0]
                    ),
                  build(<subval:string>[i=0:0,1,0],'_'),
                  probe_name
                  ),
                TCGA_PROBE_DATA_LOAD_BUF.probe_name,
                genome_wide_snp_6_probe_id
                ),
              sample_name,
              substr(sample_barcode, 0, 16)
              ) as A,
            redimension(
              TCGA_${DATE}_SAMPLE_STD,
              <sample_name:string>[sample_id = 0:*,1000,0]
              ),
            A.sample_name,
            sample_id
            ),
          ttn, '${TUMOR}'
          ),
        TCGA_${DATE}_TUMOR_TYPE_STD,
        ttn,
        tumor_type_id
        ),
      value, dcast(Mean_value, double(null))
      ),
    TCGA_${DATE}_GENOME_WIDE_SNP_6_STD
    ),
  TCGA_${DATE}_GENOME_WIDE_SNP_6_STD
  )"   


iquery -anq "remove(TCGA_PROBE_DATA_LOAD_BUF)"    > /dev/null 2>&1
rm -rf  ${path_downloaded}
rm -f ${probe_data_file}
rm -f ${sampleBarCodeFile}

