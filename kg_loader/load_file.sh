#!/bin/bash

#This is created specifically for 1000G files and suffers from some complexity. 
#Here's an example difficult case from 1000G and how it's handled:
#Chrom	Pos		ID		ref	alt	sample1	sample2...	
#2	206959388	.		T	TACAC	0|0	1|0
#2	206959388	.		T	TACACAC	...	...
#2	206959388	.		TAC	TACAC,T	...	...
#2	206959388	rs146640041	TACACAC	T	...	...

#This looks like an error, but terminating in the middle of a long load is not
#very friendly. Silently filtering data out may also be looked down upon; so 
#our script proceeds with a semi-reasonable structure.

#VARIANT array in DB (omitting chrom_id dimension and some attributes):
#start		end		alt_no	ref	alt
#206959388	206959390	1	TAC	T	
#206959388	206959392	1	T	TACAC
#206959388	206959392	2	TAC	TACAC
#206959388	206959394	1	TACACAC	T
#206959388	206959394	2	T	TACACAC

#GENOTYPE array in DB (omitting chrom_id):
#start		end		alt_no	sample_id	a1	a2	phase
#...
#206959388	206959392	1	0		false	false	true
#206959388	206959392	1	1		true	false	true
#...
#206959388	206959392	2	0		...
#206959388	206959392	2	1		...

#The complexity of this script is in decomposing the alt attribute, and 
#assigning the alt_no coordinates to be shared by those two arrays above.
#So a mask array is used as a temporary alt_no assigner.

#Overall process:
# 1) parse the whole file into a temp matrix (millions of rows, 2504 +.. cols)
# 2) fix up the chromosome and sample data
# 3) peel off the first few columns (ref,alt...) into a separate buffer
# 4) use buffer from (3) to create a mask of (chrom, start, end, alt_no)
# 5) use the mask from (4) to redim into KG_VARIANT
# 6) use the mask from (4) to redim into KG_GENOTYPE

LINES_PER_CHUNK=500
NUM_PRESAMPLE_ATTRIBUTES=9 #CHROM, POS, ID, REF, ALT, QUAL, FILTER, INFO, FORMAT
NUM_SAMPLES=2504
NUM_ATTRIBUTES=$((NUM_PRESAMPLE_ATTRIBUTES + NUM_SAMPLES))
#For Debug output
DATESTRING="+%Y_%m_%d_%H_%M_%S_%N"

function log()
{
  echo "`date $DATESTRING` > $1"
}

function error()
{
  echo "`date $DATESTRING` !!! ERROR !!! $1" >&2
  echo "KTHXBYE"
  exit 1
}

function delete_old_versions()
{
  ARRAY_NAME=$1
  MAX_VERSION=`iquery -ocsv -aq "aggregate(versions($ARRAY_NAME), max(version_id) as max_version)" | tail -n 1`
  iquery -anq "remove_versions($ARRAY_NAME, $MAX_VERSION)" > /dev/null
}

if [ $# -ne 1 ]; then
    error "Please provide the input file!"
fi
FILE=$1
filedir=`dirname $FILE`
pushd $filedir >> /dev/null
FILE="`pwd`/`basename $FILE`"
if [ ! -f $FILE ] ; then
 error "Cannot find file $FILE!"
fi
log "Loading $FILE"
popd > /dev/null
mydir=`dirname $0`
pushd $mydir >> /dev/null
mydir=`pwd`
gzip_status_command='file '$FILE' | grep gzip | wc -l'
gzip_status=`eval $gzip_status_command`
if [ $? -ne 0 ] ; then
 error "Error code running '$gzip_status_command'"
fi
gzipped=0
if [ $gzip_status -eq 0 ]; then
 log "File does not appear to be gzipped, loading direct"
elif [ $gzip_status -eq 1 ]; then
 log "File appears to be gzipped, loading through zcat"
 gzipped=1
else
 error "Unexpected result running '$gzip_status_command'; expected 1 or 0"
fi
iquery -anq "remove(KG_LOAD_BUF)" > /dev/null 2>&1
iquery -anq "remove(KG_LOAD_SAMPLE_LINE_LOCATION)" > /dev/null 2>&1
iquery -anq "remove(KG_LOAD_SAMPLE)" > /dev/null 2>&1
iquery -anq "remove(KG_LOAD_VARIANT_BUF)" > /dev/null 2>&1
iquery -anq "remove(KG_LOAD_REDIM_MASK)" > /dev/null 2>&1
fifo_path=$mydir/load.fifo
#Entering the clean zone:
set -e
rm -rf $fifo_path
mkfifo $fifo_path
if [ $gzipped -eq 1 ]; then
 zcat $FILE > $fifo_path &
else 
 cat  $FILE > $fifo_path &
fi
#Load the file
iquery -anq "create array KG_LOAD_BUF <a:string null> [source_instance_id=0:*,1,0,chunk_no=0:*,1,0,line_no=0:*,$LINES_PER_CHUNK,0,attribute_no=0:$NUM_ATTRIBUTES,$((NUM_ATTRIBUTES+1)),0]" > /dev/null
iquery -anq "store(parse(split('$fifo_path', 'lines_per_chunk=$LINES_PER_CHUNK'), 'num_attributes=$NUM_ATTRIBUTES', 'chunk_size=$LINES_PER_CHUNK', 'split_on_dimension=1'), KG_LOAD_BUF)" > /dev/null
rm -rf $fifo_path
log "File ingested"
iquery -anq "create temp array KG_LOAD_SAMPLE_LINE_LOCATION <source_instance_id:int64,chunk_no:int64,line_no:int64> [i=0:*,1,0]" > /dev/null
iquery -anq "
store(
 project(
  unpack(
   filter(
    slice(KG_LOAD_BUF, attribute_no, 0), 
    substr(a, 0, 1) = '#' and substr(a,1,1) <> '#'
   ), 
   i, 1
  ), 
  source_instance_id, chunk_no, line_no
 ),
 KG_LOAD_SAMPLE_LINE_LOCATION
)" > /dev/null
#Store sample line chunk no and sample line no
SL_CN=`iquery -ocsv -aq "project(KG_LOAD_SAMPLE_LINE_LOCATION, chunk_no)" | tail -n 1`
SL_LN=`iquery -ocsv -aq "project(KG_LOAD_SAMPLE_LINE_LOCATION, line_no)"  | tail -n 1`
log "Found the sample line at chunk $SL_CN, line number $SL_LN"
NUM_ERRORS=`iquery -ocsv -aq "
op_count(
 filter(
  slice(KG_LOAD_BUF, attribute_no, $NUM_ATTRIBUTES),
  (chunk_no > $SL_CN or line_no > $SL_LN) and a is not null
 )
)" | tail -n 1`
if [ $NUM_ERRORS -ne 0 ] ; then
 error "Found unexpected attribute errors in the data load. Examine KG_LOAD_BUF."
else
 log "Found no errors past the sample line"
fi
iquery -anq "create temp array KG_LOAD_SAMPLE <sample_name:string> [sample_id]" > /dev/null
iquery -anq "
store(
 redimension(
  substitute(
   apply(
    between(
     cross_join(
      KG_LOAD_BUF as A,
      redimension(KG_LOAD_SAMPLE_LINE_LOCATION, <i:int64> [chunk_no=0:*,1,0, line_no=0:*,$LINES_PER_CHUNK, 0]) as B,
      A.chunk_no, B.chunk_no,
      A.line_no, B.line_no
     ),
     null, null, null, $((NUM_PRESAMPLE_ATTRIBUTES)),
     null, null, null, $((NUM_ATTRIBUTES-1))
    ),
    sample_name, a,
    sample_id, attribute_no - $((NUM_PRESAMPLE_ATTRIBUTES))
   ),
   build(<val:string> [x=0:0,1,0], ''),
   sample_name
  ),
  KG_LOAD_SAMPLE
 ),
 KG_LOAD_SAMPLE
)" > /dev/null
NUM_SAMPLES_IN_FILE=`iquery -ocsv -aq "op_count(KG_LOAD_SAMPLE)" | tail -n 1`
if [ -z $NUM_SAMPLES_IN_FILE -o  $NUM_SAMPLES_IN_FILE -ne $NUM_SAMPLES ]; then
 error "Number of samples in the file does not match expected. Examine KG_LOAD_BUF."
else
 log "Confirmed $NUM_SAMPLES_IN_FILE samples in file"
fi
NUM_SAMPLES_IN_DB=`iquery -ocsv -aq "op_count(KG_SAMPLE)" | tail -n 1`
SAMPLES_ALIGNED=0
if [ $NUM_SAMPLES_IN_DB -eq 0 ]; then
 log "No samples are in DB; will populate with samples from file."
 SAMPLES_ALIGNED=1
elif [ $NUM_SAMPLES_IN_DB -ne $NUM_SAMPLES_IN_FILE ]; then
 SAMPLES_ALIGNED=0
else 
 JOINED_SAMPLES=`iquery -ocsv -aq "aggregate(apply(join(KG_LOAD_SAMPLE as A, KG_SAMPLE as B), t, iif(A.sample_id = B.sample_id, 1, 0)), sum(t))" | tail -n 1`
 if [ $JOINED_SAMPLES -ne $NUM_SAMPLES_IN_FILE ] ; then 
  SAMPLES_ALIGNED=0
 else
  SAMPLES_ALIGNED=1
 fi
fi
if [ $SAMPLES_ALIGNED -ne 1 ] ; then
 error "Samples in the file are not aligned with the samples in the DB. This script does not support that."
fi
log "Separating per-variant data into a temporary KG_LOAD_VARIANT_BUF"
iquery -anq "
create temp array KG_LOAD_VARIANT_BUF
<chrom:     string null,
 pos:       int64  null,
 id:        string null,
 ref:       string null,
 alt:       string null,
 qual:      double null,
 filter:    string null,
 info:      string null,
 format:    string null>
[source_instance_id=0:*,1,0,chunk_no=0:*,1,0,line_no=0:*,$LINES_PER_CHUNK,0]" > /dev/null
iquery -anq "
store(
 redimension(
  apply(
   between(
    filter(
     KG_LOAD_BUF,
     chunk_no > $SL_CN or line_no > $SL_LN
    ),
    null,null,null,0,
    null,null,null,$((NUM_PRESAMPLE_ATTRIBUTES-1))
   ),
   chrom,  iif(attribute_no =0, a, null),
   pos,    int64(iif(attribute_no =1, a, null)),
   id,     iif(attribute_no =2, a, null),
   ref,    iif(attribute_no =3, a, null),
   alt,    iif(attribute_no =4, a, null),
   qual,   double(iif(attribute_no =5, a, null)),
   filter, iif(attribute_no =6, a, null),
   info,   iif(attribute_no =7, a, null),
   format, iif(attribute_no =8, a, null)
  ),
  KG_LOAD_VARIANT_BUF,
  max(chrom) as chrom, max(pos) as pos, max(id) as id, max(ref) as ref, max(alt) as alt, max(qual) as qual, 
  max(filter) as filter, max(info) as info, max(format) as format
 ),
 KG_LOAD_VARIANT_BUF
)" > /dev/null
NUM_VARIANTS=`iquery -ocsv -aq "op_count(KG_LOAD_VARIANT_BUF)" | tail -n 1`
if [ $NUM_VARIANTS -le 0 ] ; then
 error "Found no variants in the file?"
else
 log "Identified $NUM_VARIANTS variants in the file"
fi
NUM_UNIQUE_CHROMOSOMES=`iquery -ocsv -aq "op_count(uniq(sort(project(KG_LOAD_VARIANT_BUF, chrom))))" | tail -n 1`
if [ $NUM_UNIQUE_CHROMOSOMES -ne 1 ] ; then
 error "File appears to have more than one chromosome, this script doesn't support that"
fi
CHROMOSOME=`iquery -ocsv -aq "uniq(sort(project(KG_LOAD_VARIANT_BUF, chrom)))" | tail -n 1`
CHROMOSOME_EXISTS=`iquery -ocsv -aq "op_count(filter(KG_CHROMOSOME, chromosome=$CHROMOSOME))" | tail -n 1`
if [ -z $CHROMOSOME -o -z $CHROMOSOME_EXISTS -o $CHROMOSOME_EXISTS -ne 0 ] ; then
 error "This chromosome is already in the KG_CHROMOSOME array"
fi
log "Creating var redimension mask"
MAX_ALTERNATES=`iquery -otsv -aq "
aggregate(
 apply(
  KG_LOAD_VARIANT_BUF,
  num_variants, 
  char_count(alt, ',') + 1
 ),
 max(num_variants) as max_alternates
)" | tail -n 1`
iquery -anq "create temp array 
KG_LOAD_REDIM_MASK
<start:int64,end:int64,alternate_id:int64> 
[source_instance_id=0:*,1,0,chunk_no=0:*,1,0,line_no=0:*,$LINES_PER_CHUNK,0,file_alt_number=1:$MAX_ALTERNATES,$MAX_ALTERNATES,0]" > /dev/null
iquery -anq "
store(
 redimension(
  redimension(
   apply(
    apply(
     cross_join(
      KG_LOAD_VARIANT_BUF as VARS,
      project(
       filter(
        cross_join(
         apply(
          KG_LOAD_VARIANT_BUF,
          num_variants,
          char_count(alt, ',') + 1
         ),
         build(<flag:bool> [file_alt_number=1:$((MAX_ALTERNATES)), $MAX_ALTERNATES,0], true)
        ),
        num_variants>=file_alt_number
       ),
       flag
      ) as MASK,
      VARS.source_instance_id, MASK.source_instance_id,
      VARS.chunk_no, MASK.chunk_no,
      VARS.line_no,  MASK.line_no
     ),
     alternate, 
     nth_csv(alt, file_alt_number-1)
    ),
    start, int64(pos),
    end,   iif(substr(alternate, 0,1) <> '<', int64(iif(strlen(ref) > strlen(alternate), strlen(ref), strlen(alternate))) + pos - 1,
           iif(keyed_value(info, 'END', null) is not null, int64(keyed_value(info, 'END', null)),
           iif(keyed_value(info, 'SVLEN', null) is not null and int64(keyed_value(info, 'SVLEN', null)) > 0, 
              int64(keyed_value(info, 'SVLEN',null)) + pos - 1, 
              pos)))
   ),
   <source_instance_id:int64, chunk_no:int64, line_no:int64, file_alt_number:int64> 
   [start=0:*,10000000,0, end=0:*,10000000,0, alternate_id=1:20,20,0]
  ),
  KG_LOAD_REDIM_MASK
 ),
 KG_LOAD_REDIM_MASK
)" > /dev/null
MASK_COUNT=`iquery -ocsv -aq "op_count(KG_LOAD_REDIM_MASK)" | tail -n 1`
if [ -z $MASK_COUNT -o $MASK_COUNT -lt $NUM_VARIANTS ]; then
 error "Mask appears incorrect"
fi 
###
if [ $NUM_SAMPLES_IN_DB -eq 0 ]; then
 log "Inserting samples from file"
 iquery -anq "store(KG_LOAD_SAMPLE, KG_SAMPLE)" > /dev/null
fi
log "Loading into KG_CHROMOSOME"
CHROMOSOME_ID=`iquery -ocsv -aq "
aggregate(
 apply(
  insert(
   redimension(
    apply(
     aggregate(
      apply(
       KG_CHROMOSOME,
       cid, chromosome_id
      ),
      max(cid) as max_chrom_id
     ),
     chromosome,      $CHROMOSOME,
     chromosome_id,   iif(max_chrom_id is null, 0, max_chrom_id + 1)
    ),
    KG_CHROMOSOME
   ),
   KG_CHROMOSOME
  ),
  acid, chromosome_id
 ),
 max(acid)
)" | tail -n 1`
if [ -z $CHROMOSOME_ID ]; then
 error "Chromosome insertion appears to have failed"
fi
log "Loading into KG_VARIANT"
iquery -anq "
insert(
 redimension(
  substitute(
   apply(
    cross_join(
     KG_LOAD_VARIANT_BUF as VAR,
     KG_LOAD_REDIM_MASK  as MASK,
     VAR.source_instance_id, MASK.source_instance_id,
     VAR.chunk_no,           MASK.chunk_no,
     VAR.line_no,            MASK.line_no
    ),
    reference, iif(ref is null, string(throw('invalid null ref')), ref),
    alternate, iif(alt is null, string(throw('invalid null alt')), nth_csv(alt, alternate_id-1)),
    ac,        double(nth_csv(keyed_value(info, 'AC', null), alternate_id -1)),
    af,        double(nth_csv(keyed_value(info, 'AF', null), alternate_id -1)),
    chromosome_id, $CHROMOSOME_ID 
   ),
   build(<val:string> [i=0:0,1,0], 'invalid'),
   reference, 
   alternate
  ), 
  KG_VARIANT
 ),
 KG_VARIANT
)" > /dev/null
log "Loading into KG_GENOTYPE"
iquery -anq "
insert(
 redimension(
  apply(
   cross_join(
    between(
     KG_LOAD_BUF,
     null, null, null, $NUM_PRESAMPLE_ATTRIBUTES, 
     null, null, null, $NUM_ATTRIBUTES-1
    ) as BUF,
    KG_LOAD_REDIM_MASK  as MASK,
    BUF.source_instance_id, MASK.source_instance_id,
    BUF.chunk_no,           MASK.chunk_no,
    BUF.line_no,            MASK.line_no    
   ),
   sample_id,  attribute_no - $NUM_PRESAMPLE_ATTRIBUTES,
   allele_1,   dcast(nth_tdv(a, 0, '|/'), int64(null)) = alternate_id,
   allele_2,   dcast(nth_tdv(a, 1, '|/'), int64(null)) = alternate_id,
   phase,      iif( char_count(a, '|') > 0, true, iif(char_count(a, '/') > 0, false, null)),
   chromosome_id, $CHROMOSOME_ID
  ),
  KG_GENOTYPE
 ),
 KG_GENOTYPE
)" > /dev/null
log "Cleaning up"
delete_old_versions "KG_CHROMOSOME"
delete_old_versions "KG_GENOTYPE"
delete_old_versions "KG_SAMPLE"
delete_old_versions "KG_VARIANT"
iquery -anq "remove(KG_LOAD_BUF)" > /dev/null
iquery -anq "remove(KG_LOAD_SAMPLE_LINE_LOCATION)" > /dev/null
iquery -anq "remove(KG_LOAD_SAMPLE)" > /dev/null
iquery -anq "remove(KG_LOAD_VARIANT_BUF)" > /dev/null
iquery -anq "remove(KG_LOAD_REDIM_MASK)" > /dev/null
log "Loaded $NUM_VARIANTS variants."

