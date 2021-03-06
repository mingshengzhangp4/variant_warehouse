# SciDB/Apache Spark-ADAM Benchmark Project

The Spark portion of the benchmark uses software from the open source repositories noted below. This is also specified in the query.sbt file in the spark_benchmark directory. 

###Software Versions

scalaVersion  "2.10.4"


org.apache.spark:spark-core   "1.2.1"


org.bdgenomics.adam:adam-core "0.16.0"


org.apache.spark:spark-mllib_2.10 "1.2.1"


org.apache.hadoop:hadoop-client  "2.6.0"

The base directory(spark_benchmark) contains the Apache Spark code and scripts for including dependencies. 
The benchmark can be built with the command "sbt package" at the base level of the spark_benchmark directory( where the query.sbt exists) using the interactive build tool.   http://www.scala-sbt.org

###An example of how to run individual benchmarks:

To time the decompression of a tar/zipped VCF file, load onto the HDFS filesystem, and convert chromosome 8 to the ADAM data model:


.\query0chrom8_1000.sh

Below are examples of scripts that submit the benchmark to Spark. The scripts will have to be modified to include the location of the ADAM software distribution and the location of the compiled benchmark jar.  

/bin/bash


nohup ./query1-submit > query1_join_normalized 2>&1 &


nohup ./query2-submit > query2_groupedcount 2>&1 &


nohup ./query3-submit > query3_pca 2>&1 &

Performance values are recorded from the Spark dashboard or timed statements within Scala. There are Spark settings to keep the dashboard up after the job has stopped running. 

Spark Jobs Dashboard Link : http://yourcluster:4040 The default port is 4040. 




