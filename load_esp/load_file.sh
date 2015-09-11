#!/bin/bash

LINES_PER_CHUNK=1000
NUM_ATTRIBUTES=8 #CHROM, POS, ID, REF, ALT, QUAL, FILTER, INFO

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
  if [ $MAX_VERSION != "null" -a $MAX_VERSION -gt 0 ] ; then
    iquery -anq "remove_versions($ARRAY_NAME, $MAX_VERSION)" > /dev/null
  fi
}

#set -x
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
iquery -anq "remove(ESP_LOAD_BUF)" > /dev/null 2>&1
iquery -anq "remove(ESP_LOAD_SAMPLE_LINE_LOCATION)" > /dev/null 2>&1
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
iquery -anq "create array ESP_LOAD_BUF 
<schrom:string null,
 spos:    string null,
 sid:     string null,
 sref:    string null,
 salt:    string null,
 squal:   string null,
 sfilter: string null,
 sinfo:   string null,
 error:   string null> 
[source_instance_id=0:*,1,0,chunk_no=0:*,1,0,line_no=0:*,$LINES_PER_CHUNK,0]" > /dev/null
iquery -anq "
store(
 parse(
  split('$fifo_path', 'source_instance_id=0', 'lines_per_chunk=$LINES_PER_CHUNK'),
  'num_attributes=$NUM_ATTRIBUTES',
  'chunk_size=$LINES_PER_CHUNK'
 ), 
 ESP_LOAD_BUF
)" > /dev/null
rm -rf $fifo_path
log "File ingested"
iquery -anq "create temp array ESP_LOAD_SAMPLE_LINE_LOCATION 
<source_instance_id:int64,chunk_no:int64,line_no:int64> 
[i=0:*,1,0]" > /dev/null
iquery -anq "
store(
 project(
  unpack(
   filter(
    project(ESP_LOAD_BUF, schrom), 
    substr(schrom, 0, 1) = '#' and substr(schrom,1,1) <> '#'
   ), 
   i, 1
  ), 
  source_instance_id, chunk_no, line_no
 ),
 ESP_LOAD_SAMPLE_LINE_LOCATION
)" > /dev/null
#Store sample line chunk no and sample line no
SL_CN=`iquery -ocsv -aq "project(ESP_LOAD_SAMPLE_LINE_LOCATION, chunk_no)" | tail -n 1`
SL_LN=`iquery -ocsv -aq "project(ESP_LOAD_SAMPLE_LINE_LOCATION, line_no)"  | tail -n 1`
log "Found the sample line at chunk $SL_CN, line number $SL_LN"
#Ich wants no errors past the sample line!
NUM_ERRORS=`iquery -ocsv -aq "
op_count(
 filter(
  project(ESP_LOAD_BUF, error),
  (chunk_no > $SL_CN or line_no > $SL_LN) and error is not null
 )
)" | tail -n 1`
if [ $NUM_ERRORS -ne 0 ] ; then
 error "Found unexpected attribute errors in the data load. Examine ESP_LOAD_BUF."
else
 log "Found no errors past the sample line"
fi
MAX_ALTERNATES=`iquery -otsv -aq "
aggregate(
 apply(
  ESP_LOAD_BUF,
  num_alternates,
  char_count(salt, ',') + 1
 ),
 max(num_alternates) 
)" | tail -n 1`
log "Redimensioning data"
iquery -anq "
insert(
 redimension(
  substitute(
   index_lookup(
    apply(
     filter(
      cross_join(
       apply(
        filter(
         ESP_LOAD_BUF, chunk_no > $SL_CN or line_no > $SL_LN
        ),
        num_vars, char_count(salt, ',') + 1
       ),
       build(<flag:bool> [alternate_id=1:$((MAX_ALTERNATES)), $MAX_ALTERNATES, 0], true)
      ),
      alternate_id <= num_vars
     ),
     reference,  sref,
     alternate,  nth_csv(salt, alternate_id-1),
     start,      int64(spos),
     end,        strlen(sref) + int64(spos) - 1,
     id,         sid,
     qual,       dcast(squal, double(null)),
     filter,     sfilter,
     info,       sinfo,  
     ea_maf,     dcast(nth_csv(keyed_value(sinfo, 'MAF', null), 0), double(null)),
     aa_maf,     dcast(nth_csv(keyed_value(sinfo, 'MAF', null), 1), double(null))
    ),
    ESP_CHROMOSOME, schrom, chromosome_id
   ),
   build(<val:string>[i=0:0,1,0], ''),
   reference, alternate
  ),
  ESP_VARIANT,
  false
 ), 
 ESP_VARIANT
)" > /dev/null
log "Cleaning up"
delete_old_versions ESP_VARIANT
