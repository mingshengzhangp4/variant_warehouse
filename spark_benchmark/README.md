name := "Spark Benchmark Project"
version := "1.0"

The Spark Benchmark is constructed with the software from the below open source repositories and software versions. This is specified in the query.sbt file in the spark_benchmark directory. 

scalaVersion := "2.10.4"
"org.apache.spark" %% "spark-core"   % "1.2.1",
"org.bdgenomics.adam" % "adam-core"  % "0.16.0",
"org.apache.spark"  %  "spark-mllib_2.10"  % "1.2.1",
"org.apache.hadoop" % "hadoop-client" % "2.6.0"

You should be able to build the benchmark the typing "sbt package" at the base level of the spark_benchmark directory( where the query.sbt exists). http://www.scala-sbt.org

An example of how to run individual benchmarks are:

To time the unzipping, load onto the HDFS filesystem, and convert to the datamodel:
.\query0chrom8_1000.sh

Below are examples of scripts that submit a query to spark.The scripts will have to be modified to include the location of the ADAM software distribution and the location of the compiled benchmark jar.  

nohup ./query1-submit > query1_join_normalized 2>&1 &
nohup ./query2-submit > query2_groupedcount 2>&1 &
nohup ./query3-submit > query3_pca 2>&1 &




