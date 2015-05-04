import scala.sys.process._
//import org.kohsuke.args4j.Argument
import scala.io.Source
import scala.reflect.ClassTag
import org.apache.spark.SparkContext.rddToPairRDDFunctions

import scala.math.random
import org.apache.spark.api.java.JavaRDD
import parquet.hadoop.metadata.CompressionCodecName

import org.apache.hadoop.mapreduce.Job
import org.apache.spark.{ Logging, SparkContext }
import org.apache.spark.SparkContext._
import org.apache.spark.rdd.RDD
import org.apache.spark._
import org.apache.spark.storage.StorageLevel._

import org.bdgenomics.adam.rdd.ADAMContext
import org.bdgenomics.adam.rdd.ADAMContext._
import org.bdgenomics.formats.avro.{ Genotype, GenotypeAllele }
import org.bdgenomics.adam.rdd.ADAMContext._
import org.bdgenomics.formats.avro._
import org.bdgenomics.adam.models._
import org.bdgenomics.adam.rdd.variation._
import org.bdgenomics.adam.models.VariantContext
import org.bdgenomics.formats.avro.{DatabaseVariantAnnotation, Variant, Genotype, FlatGenotype}
import org.bdgenomics.adam.rdd.ADAMContext

import org.apache.spark.mllib.linalg.Matrix
import org.apache.spark.mllib.linalg.distributed.RowMatrix
import org.apache.spark.mllib.linalg.SingularValueDecomposition
import org.apache.spark.mllib.linalg.Vector
import org.apache.spark.mllib.linalg.SparseVector
import org.apache.spark.mllib.linalg._


class PCAComputation extends Serializable {
  
def chooseAllele(x: (String, java.lang.Long, String, String, GenotypeAllele, String, Double )) =
    x match {
     case (chr, position, refAllele, varAllele, GenotypeAllele.Ref, sampleId, pcaval) => Some(chr, position, refAllele, varAllele, GenotypeAllele.Ref, refAllele, sampleId, pcaval)
     case (chr, position, refAllele, varAllele, GenotypeAllele.Alt, sampleId, pcaval) => Some(chr, position, refAllele, varAllele, GenotypeAllele.Alt, varAllele, sampleId, pcaval)
     case (chr, position, refAllele, varAllele, GenotypeAllele.OtherAlt, sampleId, pcaval) => Some(chr, position, refAllele, varAllele, GenotypeAllele.OtherAlt, varAllele, sampleId, pcaval)
     case _ => None
    }


def toRDD(sc: SparkContext, m: Matrix): RDD[Vector] = {
      
      val columns = m.toArray.grouped(m.numRows)
      val rows = columns.toSeq.transpose // Skip this if you want a column-major RDD.
      val vectors = rows.map(row => new DenseVector(row.toArray))
      sc.parallelize(vectors)
}


def runPCA(sc: SparkContext, outputPath: String, nCol: Int, inputData: RDD[(Long, Int, Double)]) {
 
     import org.apache.spark.SparkContext._
     import org.apache.spark.mllib.linalg.distributed.RowMatrix
     import org.apache.spark.mllib.linalg.Vectors
     
     //val nCol:Int = inputData.map({a => a._2}).distinct.count.toInt
     
     val dataRows  = inputData.groupBy(_._1).map[(Long, Vector)]{ 
     row => val (indices, values) = row._2.map(e => (e._2, e._3)).unzip
     (row._1, new SparseVector(nCol, indices.toArray, values.toArray))
     }

     val mat  = new RowMatrix(dataRows.map(_._2).persist())
     
     val svd: SingularValueDecomposition[RowMatrix, Matrix] = mat.computeSVD(3, computeU = true)
     //val svd  = mat.computeSVD(mat.numCols().toInt)

     //val U: RowMatrix = svd.U // The U factor is a RowMatrix.
     //val s: Vector    = svd.s // The singular values are stored in a local dense vector.
     //val V: Matrix    = svd.V // The V factor is a local dense matrix.
    
     // Write results to hdfs
     val V = svd.V.toArray.grouped(svd.V.numRows).toList.transpose
     sc.makeRDD(V, 1).zipWithIndex()
     .map(line => line._2 + "\t" + line._1.mkString("\t")) // make tsv line starting with column index
     .saveAsTextFile(outputPath + "/right_singular_vectors")
 
     svd.U.rows.map(row => row.toArray).zip(dataRows.map(_._1))
     .map(line => line._2 + "\t" + line._1.mkString("\t")) // make tsv line starting with row index
     .saveAsTextFile(outputPath + "/left_singular_vectors")
 
     sc.makeRDD(svd.s.toArray, 1)
     .saveAsTextFile(outputPath + "/singular_values")

}


def orgPCAtake(sc: SparkContext, outputPath: String, sampledGts: RDD[Genotype], numsamples: Int): { val numCols: Int; val inputData: RDD[(Long, Int, Double)]} =  {

     import org.apache.spark.SparkContext._

     val sampleIds           =  sampledGts.map(p => p.getSampleId).distinct
     val samplecount         =  sampleIds.count.toInt
     val colmapidx           =  sampleIds.zipWithIndex.map({case(a,b) => (a,(0.0, b.toInt, 0.0))})

     val usefulData = sampledGts.map(p => (p.getVariant.getContig.getContigName,p.getVariant.getStart, p.getVariant.getReferenceAllele,p.getVariant.getAlternateAllele,p.getAlleles.get(0),p.getAlleles.get(1), p.getSampleId, if(p.getAlleles.get(0) == GenotypeAllele.Alt ||  p.getAlleles.get(1) == GenotypeAllele.Alt  || p.getAlleles.get(0) == GenotypeAllele.OtherAlt ||  p.getAlleles.get(1) == GenotypeAllele.OtherAlt  ) 1.0 else 0.0 ))
     
     //Some(chr, position, refAllele, varAllele, GenotypeAllele.Alt, varAllele, sampleId, pcaval
     val reduced_Variants = usefulData.flatMap(p => Seq((p._1, p._2, p._3, p._4, p._5, p._7, p._8), (p._1, p._2, p._3, p._4, p._6, p._7, p._8)))
     
     val alleles = reduced_Variants.flatMap(chooseAllele)
     import org.apache.spark.SparkContext._
     val sampledall = alleles.groupBy({a =>(a._1, a._2, a._3, a._4) })
     
     val numkeys = sampledall.keys.count

     //(String, java.lang.Long, String,    String,    GenotypeAllele,     String,    String, Double )
     //(chr,    position,       refAllele, varAllele, GenotypeAllele.Alt, varAllele, sampleId, pcaval)
     val keyvals          = sampledall.keys.sample(true, numsamples.toDouble / numkeys.toDouble, 0).map({a =>(a,("",0,"","",GenotypeAllele.Alt,"","",0.0))})
     val filtersampledall = sampledall.flatMapValues(identity).join(keyvals).map({case(a,b) => (a,b._1)})

     //filtersampledall.persist(MEMORY_AND_DISK).saveAsObjectFile(outputPath + "filtersampledall")
     
     val rowmapidx = filtersampledall.map({case(a,b) =>(b._1,b._2, b._3, b._4)}).distinct.zipWithIndex().map({case(a,b) => (a,(b,0,"",0.0))})

     //rowmapidx.persist(MEMORY_AND_DISK).saveAsObjectFile(outputPath + "rowmapidx")

     val dataout:RDD[(Long, Int, Double)]   = filtersampledall.map({case(a,b) => (a,(0,0,b._7,b._8))}).join(rowmapidx).map({case(a,b) => (b._1._3 ,(b._2._1, 0, b._1._4))}).join(colmapidx).map({case(a,b) => (b._1._1, b._2._2, b._1._3)})

     //dataout.persist(MEMORY_AND_DISK).saveAsObjectFile(outputPath)

     new{
     val numCols:Int   = samplecount
     val inputData:RDD[(Long, Int, Double)] = dataout
     }

}

}//PCA Computation


object Query3 {
def main(args: Array[ String]){

val conf = new SparkConf().setMaster("spark://p4xen7:7077")
                              .setAppName("Query3")
                              .set("spark.executor.memory","100g")
                              .set("spark.driver.memory", "20g")
                              .set("spark.local.dir","/datadisk2/spark,/datadisk3/spark,/datadisk4/spark")
                              .set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
                              .set("spark.storage.memoryFraction", "0.2")
                              .set("spark.kryoserializer.buffer.mb", "20")
                              .set("spark.kryoserializer.buffer.max.mb", "20000")
                              .set("spark.kryo.referenceTracking", "true")
                              .set("spark.kryo.registrator", "org.bdgenomics.adam.serialization.ADAMKryoRegistrator")

val sc = new SparkContext(conf)
val ac = new ADAMContext(sc)

import System.{currentTimeMillis => _time}
def profile[R](code: => R, t: Long = _time) = (code, _time - t)

// usage:
//val (result, time) = profile { /* block of code to be profiled*/ }
//val (result2, time2) = profile methodToBeProfiled(foo)


def hu(s:String) = s"hdfs://10.0.20.195:9000/sandbox/$s"
def hu2(s:String) = s"hdfs://10.0.20.195:9000/sandbox/tempfiles/$s"

//val sampledGts:RDD[Genotype] = ac.loadGenotypes(hu("example20k.vcf.adam"))
//$$$$$$$$$$$$$$$$$$$$ Test 1 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
val sampledGts:RDD[Genotype] = ac.loadGenotypes(hu("ALL.chr8.phase3_shapeit2_mvncall_integrated_v4.20130502.genotypes.vcf.adam")).persist()
val numsamples = 1000000
val PCAoutputPath = hu2("PCAoutputChrom8MillionV1")
val outputPath    = hu2("PCAChrom8MillionV1")
//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

import org.bdgenomics.adam.models._
import org.bdgenomics.adam.rdd.variation._

val (result,time) = profile {

val allcountobj = new PCAComputation 

val pcainput = allcountobj.orgPCAtake(sc,outputPath, sampledGts, numsamples)

//val inputData  = sc.objectFile[(Long, Int, Double)](outputPath)
allcountobj.runPCA(sc, PCAoutputPath, pcainput.numCols, pcainput.inputData)

//val svd: SingularValueDecomposition[RowMatrix, Matrix] = allcountobj.runPCA(sc)
//allcountobj.runPCA(sc, PCAoutputPath, pcainput.numCols, pcainput.inputData)

}//time profiling

val outputstr = s"ProcessingTime: $time"
val outputdata:RDD[String] = sc.parallelize(List(outputstr))
    outputdata.take(1).foreach(println)

}//main
}//
