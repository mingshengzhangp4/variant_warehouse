export M2_HOME=/home/bio/apache-maven-3.3.1
export M2=$M2_HOME/bin
export MAVEN_OPTS="-Xms256m -Xmx512m"
export PATH=$M2:$PATH

export JAVA_HOME=/home/bio/jdk1.7.0_75
export PATH=$JAVA_HOME/bin:$PATH

export SPARK_HOME=/home/bio/spark-1.2.1-bin-hadoop2.4
export ADAM_HOME=/home/bio/adam-distribution-0.16.0
export SPARK_WORKER_DIR=/datadisk1/spark
export HADOOP_INSTALL=/home/bio/hadoop-2.6.0

export PATH=$PATH:$HADOOP_INSTALL/bin
export PATH=$PATH:$HADOOP_INSTALL/sbin
export HADOOP_MAPRED_HOME=$HADOOP_INSTALL
export HADOOP_COMMON_HOME=$HADOOP_INSTALL
export HADOOP_HDFS_HOME=$HADOOP_INSTALL
export YARN_HOME=$HADOOP_INSTALL
export HADOOP_PREFIX=$HADOOP_INSTALL

export MASTER=spark://p4xen7:7077

alias adam-submit="${ADAM_HOME}/bin/adam-submit"
alias adam-shell="${ADAM_HOME}/bin/adam-shell"
alias startspark="/home/bio/spark-1.2.1-bin-hadoop2.4/sbin/start-all.sh"
alias stopspark="/home/bio/spark-1.2.1-bin-hadoop2.4/sbin/stop-all.sh"

