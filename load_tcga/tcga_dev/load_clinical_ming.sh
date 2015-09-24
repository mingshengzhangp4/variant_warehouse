#!/bin/bash

if [ $# -ne 2 ]; then
 echo "Need two arguments: date and tumor"
 exit 1
fi

DATE=$1
TUMOR=$2

#DATE="2015_06_01"
#TUMOR="BRCA"


DATE_SHORT=`echo $DATE | sed -s "s/_//g"`
echo $DATE_SHORT

path_downloaded=/home/mzhang/Documents/tcga_download


#We found sometimes the "merged" file has NA fields where one of the other files has the same fields populated for the same key!!!
#Sadface.
#So our approach is to cat all the files into one, load that, then pick values on all non-NA keys.

# wget -P ${path_downloaded} http://gdac.broadinstitute.org/runs/stddata__${DATE}/data/${TUMOR}/${DATE_SHORT}/gdac.broadinstitute.org_${TUMOR}.Merge_Clinical.Level_1.${DATE_SHORT}00.0.0.tar.gz


# tar -zxvf ${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_Clinical.Level_1.${DATE_SHORT}00.0.0.tar.gz --directory ${path_downloaded}


echo "unzipped tar.gz. Continue?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1;;
    esac
done


MYDIR=${path_downloaded}/gdac.broadinstitute.org_${TUMOR}.Merge_Clinical.Level_1.${DATE_SHORT}00.0.0

#Also, ESCA has an auxiliary file that breaks the pattern. Dont load that for now.
rm -f $MYDIR/*auxiliary*

CLIN_FILE=$MYDIR/clinical.txt
# cat $MYDIR/${TUMOR}.*txt | tail -n +2  > $CLIN_FILE


echo "merged 3 files. Continue?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1;;
    esac
done


CLIN_NUM_COLUMNS=`cat $CLIN_FILE | awk  -F '\t' '{print NF}' | head -n 1`


echo $CLIN_NUM_COLUMNS
echo "found column number. Continue?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1;;
    esac
done





#   iquery -anq "remove(TCGA_CLIN_LOAD_BUF)"    > /dev/null 2>&1
#   iquery -anq "create temp array TCGA_CLIN_LOAD_BUF
#   <field:string null>
#   [source_instance_id = 0:*,1,0,
#    chunk_number       = 0:*,1,0,
#    line_number        = 0:*,1000,0,
#    column_number      = 0:$CLIN_NUM_COLUMNS, $((CLIN_NUM_COLUMNS+1)), 0]"
#  
#  
#  echo "set up template array TCGA_CLIN_LOAD_BUF. Continue?"
#  select yn in "yes" "no"; do
#      case $yn in
#          yes) break;;
#          no ) exit 1;;
#      esac
#  done
#  
#  
#    iquery -anq "
#    store(
#     parse(
#      split('$CLIN_FILE', 'header=0', 'lines_per_chunk=1000'),
#      'chunk_size=1000', 'split_on_dimension=1', 'num_attributes=$CLIN_NUM_COLUMNS'
#     ),
#     TCGA_CLIN_LOAD_BUF
#    )" 
#  

echo "populated array TCGA_CLIN_LOAD_BUF. Continue?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1;;
    esac
done


##  MISMATCH_COUNT=`iquery -ocsv -aq "
##  op_count(
##   filter(
##    aggregate(
##     cross_join(
##      TCGA_CLIN_LOAD_BUF as A, 
##      redimension(
##       filter(
##        between(TCGA_CLIN_LOAD_BUF, null, null, null, 0, null, null, null, 0), 
##        field='patient.bcr_patient_barcode'
##       ), 
##       <field:string null> [chunk_number=0:*,1,0, line_number=0:*,1000,0]
##      ) as B, 
##      A.chunk_number, B.chunk_number, A.line_number, B.line_number
##     ), 
##     min(A.field) as a, 
##     max(A.field) as b, 
##     column_number
##    ), 
##    a<>b
##   )
##  )" | tail -n 1`
##  
##  if [ $MISMATCH_COUNT -ne 0 ]; then
##   echo "File column mismatch. Sorry brah!"
##   exit 1
##  fi


echo "checked if file column mismatch. Continue?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1;;
    esac
done


  PATIENTS_LOCATION=`iquery -ocsv -aq "project(unpack(filter(between(TCGA_CLIN_LOAD_BUF, null, null, null, 0, null, null, null, 0), field='patient.bcr_patient_barcode'), z), chunk_number, line_number)" | tail -n 1`
   
  
  echo "patients_location:"
  echo ${PATIENTS_LOCATION}
  echo "got PATIENTS_LOCATION. Continue?"
  select yn in "yes" "no"; do
      case $yn in
          yes) break;;
          no ) exit 1;;
      esac
  done
  
##  echo "Generate patients_list?"
##  select yn in "yes" "no"; do
##      case $yn in
##          yes) break;;
##          no ) exit 1;;
##      esac
##  done
##  
##  
##  iquery -otsv -aq "between(TCGA_CLIN_LOAD_BUF, 0, $PATIENTS_LOCATION, 1, 0, $PATIENTS_LOCATION, $CLIN_NUM_COLUMNS-1)" | tail -n +2 | sed -e 's/\(.*\)/\U\1/' > $MYDIR/patients.tsv
##  
##  echo "Done. Continue?"
##  select yn in "yes" "no"; do
##      case $yn in
##          yes) break;;
##          no ) exit 1;;
##      esac
##  done
##  

echo "Generate clinical keys?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1;;
    esac
done


##  iquery -naq "remove(TCGA_CLIN_KEYS)" > /dev/null 2>&1
##  iquery -naq "
##  store(
##   cast(
##    uniq(
##     sort(
##      project(
##       between(TCGA_CLIN_LOAD_BUF, null, null, null, 0, null, null, null, 0), 
##       field
##      )
##     )
##    ),
##    <key:string> [clinical_line_nbr=0:*,1000000,0]
##   ), 
##   TCGA_CLIN_KEYS
##  )"
##  
  echo "Done. Continue?"
  select yn in "yes" "no"; do
      case $yn in
          yes) break;;
          no ) exit 1;;
      esac
  done
  

echo "Insert new patients?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1;;
    esac
done


##  iquery -anq "
##  insert(
##   redimension(
##    index_lookup(
##     apply(
##      cross_join(
##       unpack(
##        filter(
##         index_lookup(
##          input(<patient_name:string>[z=0:*,1000000,0], '$MYDIR/patients.tsv', 0, 'tsv') as A,
##          redimension(TCGA_${DATE}_PATIENT_STD, <patient_name:string> [patient_id=0:*,1000000,0]) as B,
##          A.patient_name, 
##          pid
##         ),
##         pid is null
##        ),
##        patient_no
##       ),
##       aggregate( apply(TCGA_${DATE}_PATIENT_STD, pid, patient_id), max(pid) as mpid)
##      ),
##      ttn, '${TUMOR}',
##      patient_id, iif(mpid is null, patient_no, mpid+1+patient_no)
##     ),
##     TCGA_${DATE}_TUMOR_TYPE_STD,
##     ttn,
##     tumor_type_id
##    ),
##    TCGA_${DATE}_PATIENT_STD 
##   ),
##   TCGA_${DATE}_PATIENT_STD
##  )"


echo "Done. Continue?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1;;
    esac
done

echo "Insert clinical data?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1;;
    esac
done



iquery -anq "
insert(
 redimension(
  substitute(
   index_lookup(
    index_lookup(
     index_lookup(
      apply(
       cross_join(
        cross_join(
         filter(
          between(TCGA_CLIN_LOAD_BUF, null,null,null,1, null,null,null,null),
          field<>'NA'
         ) as A,
         redimension(
          input(<patient_name:string>[column_number=1:*,1000000,0], '$MYDIR/patients.tsv', 0, 'tsv'),
          <patient_name:string> [column_number= 0:$CLIN_NUM_COLUMNS, $((CLIN_NUM_COLUMNS+1)), 0]
         ) as B, 
         A.column_number, B.column_number
        ) as C,
        between(TCGA_CLIN_LOAD_BUF, null, null, null, 0, null, null, null, 0) as D,
        C.source_instance_id, D.source_instance_id,
        C.chunk_number, D.chunk_number,
        C.line_number, D.line_number
       ),
       key,   D.field,
       value, C.field,
       ttn, '${TUMOR}'
      ) as E,
      redimension(TCGA_${DATE}_PATIENT_STD, <patient_name:string> [patient_id=0:*,1000000,0]) as F,
      E.patient_name,
      patient_id
     ) as F,
     TCGA_${DATE}_TUMOR_TYPE_STD,
     F.ttn,
     tumor_type_id
    ) as G,
    TCGA_CLIN_KEYS,
    F.key,
    clinical_line_nbr
   ),
   build(<val:string>[i=0:0,1,0], 'NA'),
   key
  ),
  TCGA_${DATE}_CLINICAL_STD,
  false
 ),
 TCGA_${DATE}_CLINICAL_STD
)"


echo "Done. Continue?"
select yn in "yes" "no"; do
    case $yn in
        yes) break;;
        no ) exit 1;;
    esac
done


iquery -aq "remove(TCGA_CLIN_KEYS)"
iquery -aq "remove(TCGA_CLIN_LOAD_BUF)"
rm $MYDIR/patients.tsv
rm $CLIN_FILE
