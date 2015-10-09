#!/bin/bash

if [ $# -ne 2 ]; then
 echo "Need 2 arguments: date, tumor"
 exit 1
fi

DATE=$1
TUMOR=$2

DATE_SHORT=`echo $DATE | sed  "s/_//g"`
echo $DATE_SHORT

## iquery -anq "remove(TCGA_${DATE}_METHYLATION_STD)"

cwd=`pwd`
path_downloaded=${cwd}/tcga_download

##  mkdir -p ${path_downloaded}
##  
##  #### wget http://gdac.broadinstitute.org/runs/stddata__2015_06_01/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.2015060100.0.0.tar.gz
##  
##  
##  {
##  wget -nv -P ${path_downloaded}  http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
##  } ||{
##  echo "This file does not exist:"
##  echo http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.${DATE_SHORT}00.0.0.tar.gz
##  echo "exiting ..."
##  exit 1
##  }
##  
##    tar -zxvf ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.${DATE_SHORT}00.0.0.tar.gz --directory ${path_downloaded}/
##  

select yn in "yes" "no"; do
    case $yn in 
        yes) break;;
        no) exit 1;;
    esac
done


##    ##  create intermediate tsv files for easy loading  ##
##  
##  input_path=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.${DATE_SHORT}00.0.0
##  methyl_file=${TUMOR}.methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.data.txt
##  input_file=${input_path}/${methyl_file}
##  python methylation_file_parser.py ${input_file}

echo "python script completed..."
select yn in "yes" "no"; do
    case $yn in 
        yes) break;;
        no) exit 1;;
    esac
done


## ## update patient array ##
## 
## sampleBarCodeFile=${cwd}/methyl_sample_barcodes.txt
## iquery -anq "
## insert(
##   redimension(
##     index_lookup(
##       apply(
##         cross_join(
##           uniq(
##             sort(
##               project(
##                 filter(
##                   index_lookup(
##                     uniq(
##                       sort(
##                         project(
##                           apply(
##                             input(
##                               <sample_barcode:string> [sampleID=0:*,1000,0],
##                               '${sampleBarCodeFile}', 0, 'tsv'
##                               ),
##                             patient_name,
##                             substr(sample_barcode, 0, 12)
##                             ),
##                           patient_name)
##                         )
##                       ) as A,
##                     uniq(
##                       sort(
##                         redimension(
##                           TCGA_${DATE}_PATIENT_STD,
##                           <patient_name:string>[patient_id=0:*,1000,0]
##                           )
##                         )
##                       ) as B,
##                     A.patient_name,
##                     pat_index
##                     ),
##                   pat_index is null
##                   ),
##                 patient_name
##                 )
##               )
##             ) as new_patients,
##           aggregate(
##             apply(
##               TCGA_${DATE}_PATIENT_STD,
##               pid,
##               patient_id
##               ),
##             max(pid) as mpid
##             )
##           ),
##         ttn, '${TUMOR}',
##         patient_id, iif(mpid is null, new_patients.i, mpid+1+new_patients.i)
##         ),
##       TCGA_${DATE}_TUMOR_TYPE_STD,
##       ttn,
##       tumor_type_id
##       ),
##     TCGA_${DATE}_PATIENT_STD
##     ),
##   TCGA_${DATE}_PATIENT_STD
##   )"  
## 
## echo "patient array updating completed..."
## select yn in "yes" "no"; do
##     case $yn in 
##         yes) break;;
##         no) exit 1;;
##     esac
## done
## 
## # update sample array #
## iquery -anq"
## insert(
##   redimension(
##     index_lookup(
##       apply(
##         index_lookup(
##           apply(
##             apply(
##               cross_join(
##                 uniq(sort(
##                   project(               
##                     filter(
##                       index_lookup(
## 
##                         apply(
##                           input(
##                             <sample_barcode:string> [sampleID=0:*,1000,0],
##                             '${sampleBarCodeFile}', 0, 'tsv'
##                             ),
##                           sample_name,
##                           substr(sample_barcode, 0, 16)
##                           ) as B,
##   
##                         redimension(
##                           TCGA_${DATE}_SAMPLE_STD,
##                           <sample_name:string>[sample_id = 0:*,1000,0]
##                           ) as C,
##   
##                         B.sample_name,
##                         sample_id
##                         ),
##                       sample_id is null
##                       ),
##                     sample_name
##                     )
##                   )) as new_samples,
##                 aggregate(
##                   apply(
##                     TCGA_${DATE}_SAMPLE_STD, sample_index, sample_id),
##                   max(sample_index) as max_sid
##                   )
##                 ),
##               sample_id, iif(max_sid is null, new_samples.i, max_sid+1+new_samples.i)
##               ),
##               ttn, '${TUMOR}',
##               sample_type_id, 0
##               ) as D,
##             TCGA_${DATE}_TUMOR_TYPE_STD,
##             D.ttn,
##             tumor_type_id
##             ),
##           patient_name,
##           substr(sample_name, 0,12)
##           ) as E,
##         redimension(
##           TCGA_${DATE}_PATIENT_STD,
##           <patient_name:string>[patient_id=0:*,1000,0]
##           ),
##         E.patient_name,
##         patient_id
##         ),
##       TCGA_${DATE}_SAMPLE_STD
##     ),
##   TCGA_${DATE}_SAMPLE_STD
##   )"
##     
## echo "sample array updating completed..."
## select yn in "yes" "no"; do
##     case $yn in 
##         yes) break;;
##         no) exit 1;;
##     esac
## done
## 
## 
## geneFile=${cwd}/methyl_genes.txt
## iquery -anq "
## insert(
##   redimension(
##     apply(
##       cross_join(
##         substitute(
##           uniq(
##             sort(
##               project(
##                 filter(
##                   index_lookup(
##                     input(
##                     <gene_:string>[gene_id=0:*,1000000,0], 
##                     '${geneFile}',0,'tsv'
##                     ) as A,
## 
##                     uniq(sort(
##                       redimension(
##                         substitute(
##                           TCGA_${DATE}_GENE_STD,
##                           build(<subval:string>[i=0:0,1,0],'_'),
##                           gene_symbol
##                           ),
##                         <gene_symbol:string> [gene_id=0:*,1000000,0]
##                         )
##                       )) as B,
##                     gene_, 
##                     gid
##                     ),
##                   gid is null
##                   ),
##                 gene_
##                 )
##               )
##             ),
##           build(<subval:string>[i=0:0,1,0], '_'),
##           gene_ 
##           ) as new_genes,
## 
##         aggregate( apply(TCGA_${DATE}_GENE_STD, gid, gene_id), max(gid) as mgid)
##       ),
##       gene_symbol, gene_,
##       gene_id, iif(mgid is null, new_genes.i, mgid+1+new_genes.i),
##       entrez_geneID, int64(0),
##       start_, '_',
##       end_, '_',
##       strand_, '_',
##       hgnc_synonym, '_',
##       synonym, '_',
##       dbXrefs, '_',
##       cyto_band, '_',
##       full_name, '_',
##       type_of_gene, '_',
##       chrom, '_',
##       other_locations, '_'
##       ),
##     TCGA_${DATE}_GENE_STD
##     ),
##   TCGA_${DATE}_GENE_STD
##   )"
## 
## echo "gene array updating completed..."
## select yn in "yes" "no"; do
##     case $yn in 
##         yes) break;;
##         no) exit 1;;
##     esac
## done
## 




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

iquery -anq "remove(TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD)"
iquery -anq "create array
TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD
<probe_name:string null,
reference_chromosome:string null,
genomic_start:int64 null,
genomic_end:int64 null,
reference_gene_symbols:string null>
[gene_id=0:*,1000000,0,
humanmethylation450_probe_id=0:*,1000,0]"


iquery -aq "
redimension(
  apply(
    index_lookup(
      apply(TCGA_PROBE_LOAD_BUF,
        probe_id,
        chunk_number * ${chunk_size} + line_number
        ) as A,
      substitute(
        redimension(
          TCGA_${DATE}_GENE_STD,
          <gene_symbol:string null>
          [gene_id=0:*, 1000000,0]
          ),
        build(<subval:string>[i=0:0,1,0],'_'),
        gene_symbol
        ),
      A.gene_symbol, gene_id
      ),
    humanmethylation450_probe_id, probe_id,
    genomic_start, dcast(genomic_start_,int64(null)),
    genomic_end, dcast(genomic_start_, int64(null))
    ),
  TCGA_${DATE}_HUMANMETHYLATION450_PROBE_STD)
  
"


echo "debuging..."
select yn in "yes" "no"; do
    case $yn in 
        yes) break;;
        no) exit 1;;
    esac
done




methyl_dataFile=${cwd}/methyl_data.txt
column_no=`cat ${methyl_dataFile}|awk -F'\t' '{print NF}' |head -n 1|awk '{print $1}'`
 

## iquery -anq "remove(TCGA_METHYLATION_LOAD_BUF)"    > /dev/null 2>&1
##   
## iquery -anq "create temp array TCGA_METHYLATION_LOAD_BUF
## <val:string null>
## [source_instance_id = 0:*,1,0,
##  chunk_number       = 0:*,1,0,
##  line_number        = 0:*,1000,0,
##  col_number         = 0:$((column_no)), $((column_no+1)), 0]"
## 
## # col_number = column_no + 1(for 'error' column)
## 
## 
## iquery -anq "
## store(
##  parse(
##   split('${methyl_dataFile}', 'header=0', 'lines_per_chunk=1000'),
##   'chunk_size=1000', 'split_on_dimension=1', 'num_attributes=$((column_no))'
##  ),
##  TCGA_METHYLATION_LOAD_BUF
## )" 

##                           input(
##                             <sample_barcode:string> [sampleID=0:*,1000,0],
##                             '${sampleBarCodeFile}', 0, 'tsv'
##                             ),
#
sampleBarCodeFile=${cwd}/methyl_sample_barcodes.txt 
iquery -aq "

                      cross_join(
                        between(
                          redimension(
                            apply(
                                TCGA_METHYLATION_LOAD_BUF,
                                probe_id,
                                1000*chunk_number + line_number
                              ),
                            <val:string null>
                            [col_number=0:*,1000000,0,
                             probe_id=0:*,1000,0]
                            ),
                          0, null, $((column_no-1)), null
                          ) as G,
                        apply(
                          input(
                            <sample_barcode:string>
                            [sample_id=0:*, 1000000,0],
                            '${sampleBarCodeFile}',
                            0,
                            'tsv'
                            ),
                          sample_name,
                          substr(sample_barcode, 0, 16)
                          ),

                        G.col_number,
                        sample_id
                        )                     "

echo "debuging..."
select yn in "yes" "no"; do
    case $yn in 
        yes) break;;
        no) exit 1;;
    esac
done

## loading METHYLATION data in one step; for two steps, see what follows ##
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
                                TCGA_METHYLATION_LOAD_BUF,
                                probe_id,
                                1000*chunk_number + line_number
                              ),
                            <val:string null>
                            [col_number=0:*,1000000,0,
                             probe_id=0:*,1000,0]
                            ),
                          0, null, $((column_no-1)), null
                          ) as G,
                        apply(
                          input(
                            <sample_barcode:string>
                            [sample_id=0:*, 1000000,0],
                            '${sampleBarCodeFile}',
                            0,
                            'tsv'
                            ),
                          sample_name,
                          substr(sample_barcode, 0, 16)
                          ),
                        G.col_number,
                        sample_id
                        ) as U,

                      input(
                       <entrezID:string null>
                       [probe_id=0:*, 1000,0],
                       '${Entrez_geneList}',
                       0,
                       'tsv'
                       ) as N,
                      U.probe_id,
                      N.probe_id
                      ),
                    ttn, '${TUMOR}',
                    val, dcast(expression, double(null))
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
          val
          ),
        build(<subVal:int64>[i=0:0,1,0], 0),
        tumor_type_id, en_geneID, sample_id
        ),
      <tumor_type_id: int64,
       probe_id: int64,
       sample_id: int64,
       val:double null>
      [i=0:*,1000,0,
       j=0:*,1000,0]
      ),
    TCGA_${DATE}_METHYLATION_STD
    ),
  TCGA_${DATE}_METHYLATION_STD
  )"


iquery -anq "remove(TCGA_METHYLATION_LOAD_BUF)"    > /dev/null 2>&1
rm -rf  ${path_downloaded}
