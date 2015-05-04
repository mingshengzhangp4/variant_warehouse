#!/bin/bash
START=$(date +%s)

#start 
infolder=/home/bio/testdata/
unzipvcffile=ESP6500SI-V2-SSA137.GRCh38-liftover.chr8.snps_indels.vcf
suffix=.gz

STARTZIP=$(date +%s)
#gunzip $infolder$unzipvcffile
ENDZIP=$(date +%s)

unzipvcffile=${unzipvcffile%$suffix}

STARTHDFS=$(date +%s)
hdfs dfs -put $infolder$unzipvcffile /sandbox/$unzipvcffile
ENDHDFS=$(date +%s)

STARTADAM=$(date +%s)
/home/bio/adam/bin/adam-submit vcf2adam -onlyvariants hdfs://10.0.20.195:9000/sandbox/$unzipvcffile hdfs://10.0.20.195:9000/sandbox/${unzipvcffile}.adam
ENDADAM=$(date +%s)

#end 

DIFFZIP=$(( $ENDZIP - $STARTZIP ))
echo "The UNZIP process took $DIFFZIP seconds" >> resultquery1chrom8_ESP.txt

DIFFHDFS=$(( $ENDHDFS - $STARTHDFS ))
echo "The HDFS PUT process took $DIFFHDFS seconds" >> resultquery1chrom8_ESP.txt

DIFFADAM=$(( $ENDADAM - $STARTADAM ))
echo "The ADAM process took $DIFFADAM seconds" >> resultquery1chrom8_ESP.txt

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "The whole process took $DIFF seconds" >> resultquery1chrom8_ESP.txt

