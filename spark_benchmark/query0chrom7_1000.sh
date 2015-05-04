#!/bin/bash
START=$(date +%s)

#start 
infolder=/home/bio/jrivers/testdata/
unzipvcffile=ALL.chr7.phase3_shapeit2_mvncall_integrated_v4.20130502.genotypes.vcf
suffix=.gz

STARTZIP=$(date +%s)
#gunzip $infolder$unzipvcffile
ENDZIP=$(date +%s)

unzipvcffile=${unzipvcffile%$suffix}

STARTHDFS=$(date +%s)
#hdfs dfs -put $infolder$unzipvcffile /sandbox/$unzipvcffile
ENDHDFS=$(date +%s)

STARTADAM=$(date +%s)
/home/bio/jrivers/adam/bin/adam-submit vcf2adam hdfs://10.0.20.195:9000/sandbox/$unzipvcffile hdfs://10.0.20.195:9000/sandbox/${unzipvcffile}.adam
ENDADAM=$(date +%s)


#end 

DIFFZIP=$(( $ENDZIP - $STARTZIP ))
echo "The UNZIP process took $DIFFZIP seconds"

DIFFHDFS=$(( $ENDHDFS - $STARTHDFS ))
echo "The HDFS PUT process took $DIFFHDFS seconds"

DIFFADAM=$(( $ENDADAM - $STARTADAM ))
echo "The ADAM process took $DIFFADAM seconds"

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "The whole process took $DIFF seconds"

