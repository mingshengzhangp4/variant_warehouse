#!/bin/bash

RIND="1"
NUM_ATTRIBUTES=10
LINES_PER_CHUNK=100000
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
iquery -anq "remove(GVCF_LOAD_BUF_$RIND)" > /dev/null 2>&1
iquery -anq "remove(GVCF_LOAD_SAMPLE_LINE_LOCATION_$RIND)" > /dev/null 2>&1
fifo_path=$mydir/load_$RIND.fifo
#Entering the clean zone:
set -e
rm -rf $fifo_path
mkfifo $fifo_path
if [ $gzipped -eq 1 ]; then
 zcat $FILE > $fifo_path &
else
 cat  $FILE > $fifo_path &
fi
iquery -anq "create array GVCF_LOAD_BUF_$RIND
<a0:string NULL DEFAULT null,
 a1:string NULL DEFAULT null,
 a2:string NULL DEFAULT null,
 a3:string NULL DEFAULT null,
 a4:string NULL DEFAULT null,
 a5:string NULL DEFAULT null,
 a6:string NULL DEFAULT null,
 a7:string NULL DEFAULT null,
 a8:string NULL DEFAULT null,
 a9:string NULL DEFAULT null,
 error:string NULL DEFAULT null> 
[source_instance_id=0:*,1,0,chunk_no=0:*,1,0,line_no=0:*,100000,0]" > /dev/null 2>&1
iquery -n -aq "store(parse(split('$fifo_path', 'lines_per_chunk=$LINES_PER_CHUNK'), 'num_attributes=$NUM_ATTRIBUTES', 'chunk_size=$LINES_PER_CHUNK'), GVCF_LOAD_BUF_$RIND)" > /dev/null 2>&1
rm -rf $fifo_path
iquery -anq "
store(
 project(
  unpack(
   filter(
    project(GVCF_LOAD_BUF_$RIND, a0), 
     substr(a0, 0, 1) = '#' and substr(a0,1,1) <> '#'
    ), 
   i, 1
  ), 
  source_instance_id, chunk_no, line_no
 ),
 GVCF_LOAD_SAMPLE_LINE_LOCATION_$RIND
)" > /dev/null
#Store sample line chunk no and sample line no
SL_CN=`iquery -ocsv -aq "project(GVCF_LOAD_SAMPLE_LINE_LOCATION_$RIND, chunk_no)" | tail -n 1`
SL_LN=`iquery -ocsv -aq "project(GVCF_LOAD_SAMPLE_LINE_LOCATION_$RIND, line_no)"  | tail -n 1`
log "Found the sample line at chunk $SL_CN, line number $SL_LN"
#Ich wants no errors past the sample line!
NUM_ERRORS=`iquery -ocsv -aq "
op_count(
 filter(
  GVCF_LOAD_BUF_$RIND, (chunk_no > $SL_CN or line_no > $SL_LN) and error is not null
 )
)" | tail -n 1`
if [ $NUM_ERRORS -ne 0 ] ; then
 error "Found unexpected attribute errors in the data load. Examine KG_LOAD_BUF_$RIND."
else
 log "Found no errors past the sample line"
fi
#Enterling clean zone
set -e
SAMPLE_NAME=`iquery -o csv -aq "project(between(GVCF_LOAD_BUF_$RIND, 0, $SL_CN, $SL_LN, 0, $SL_CN, $SL_LN), a9)" | tail -n 1`
log "Adding sample $SAMPLE_NAME" 
SAMPLE_ID=`iquery -ocsv -aq "
aggregate(
 apply(
  filter(
   insert(
    redimension(
     apply(
      join(
       aggregate(GVCF_SAMPLE, count(*) as num_samples),
       aggregate(filter( apply(GVCF_SAMPLE, sid, sample_id), sample= $SAMPLE_NAME), max(sid) as existing_sample_id)
      ),
      sample_id, int64( iif(existing_sample_id is not null, existing_sample_id, num_samples) ),
      sample, $SAMPLE_NAME
     ),
     GVCF_SAMPLE
    ),
    GVCF_SAMPLE
   ),
   sample = $SAMPLE_NAME
  ),
  sid, sample_id
 ),
 max(sid)
)" | tail -n 1`
log "Added sample id $SAMPLE_ID"
log "Loading chromosomes"
iquery -anq "
insert(
 redimension(
  apply(
   cross_join(
    project(
     unpack(
      filter(
       index_lookup(
        uniq(
         sort(
          project(
           filter(
            GVCF_LOAD_BUF_$RIND,
            chunk_no > $SL_CN or line_no > $SL_LN
           ),
           a0
          )
         )
        ),
        GVCF_CHROMOSOME,
        a0,
        chrom_idx
       ),
       chrom_idx is null
      ),
      j
     ),
     a0
    ),
    aggregate(GVCF_CHROMOSOME, count(*) as count)
   ),
   chromosome_id, j + count,
   chromosome, a0
  ),
  GVCF_CHROMOSOME
 ),
 GVCF_CHROMOSOME
)" > /dev/null
log "Loading data"
iquery -anq "
insert(
 redimension(
  index_lookup(
   apply(
    filter(GVCF_LOAD_BUF_$RIND, chunk_no > $SL_CN or line_no > $SL_LN),
    start, int64(a1),
    end,   int64(keyed_value(a7, 'END', a1)),
    ref,   a3,
    alts,  a4,
    info,  a7,
    chrom, a0,
    gt,    format_extract(a8, a9, 'GT'),
    dp,    int64(format_extract(a8, a9, 'DP')),
    ad,    format_extract(a8, a9, 'AD'),
    pl,    format_extract(a8, a9, 'PL'),
    sample_id, $SAMPLE_ID
   ),
   GVCF_CHROMOSOME,
   chrom,
   chromosome_id
  ),
  GVCF_DATA, count(*) as count
 ),
 GVCF_DATA
)" > /dev/null
log "Cleaning up"
delete_old_versions "GVCF_CHROMOSOME"
delete_old_versions "GVCF_DATA"
delete_old_versions "GVCF_SAMPLE"
iquery -anq "remove(GVCF_LOAD_BUF_$RIND)" > /dev/null
iquery -anq "remove(GVCF_LOAD_SAMPLE_LINE_LOCATION_$RIND)" > /dev/null

