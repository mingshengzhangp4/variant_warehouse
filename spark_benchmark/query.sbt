name := "Spark Project"

version := "1.0"

scalaVersion := "2.10.4"

libraryDependencies ++=Seq(
                    "org.apache.spark" %% "spark-core"   % "1.2.1",
                    "org.bdgenomics.adam" % "adam-core"  % "0.16.0",
                    "org.apache.spark"  %  "spark-mllib_2.10"  % "1.2.1",
                    "org.apache.hadoop" % "hadoop-client" % "2.6.0" 
)

