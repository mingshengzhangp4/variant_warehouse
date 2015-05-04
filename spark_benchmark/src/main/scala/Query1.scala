import scala.sys.process._
import org.apache.hadoop.mapreduce.Job
import org.apache.spark.{ Logging, SparkConf, SparkContext }
import org.apache.spark.SparkContext._
import org.apache.spark.rdd.RDD
import org.bdgenomics.adam.rdd.ADAMContext._
import org.bdgenomics.formats.avro.{DatabaseVariantAnnotation, Variant, Genotype, GenotypeAllele, FlatGenotype}

import org.bdgenomics.adam.rdd.ADAMContext

//import org.kohsuke.args4j.Argument
import scala.io.Source
import scala.reflect.ClassTag
import org.apache.spark.SparkContext.rddToPairRDDFunctions


class AlleleJoin extends Serializable {
  
def chooseAllele(x: (String, java.lang.Long, String, String, GenotypeAllele)) =
    x match {
    case (chr, position, refAllele, varAllele, GenotypeAllele.Ref) => Some(chr, position, refAllele, varAllele, refAllele)
    case (chr, position, refAllele, varAllele, GenotypeAllele.Alt) => Some(chr, position, refAllele, varAllele, varAllele)
    case (chr, position, refAllele, varAllele, GenotypeAllele.OtherAlt) => Some(chr, position, refAllele, varAllele, varAllele)  
    case _ => None
    }

def denormalizejoin(sc: org.apache.spark.SparkContext, outputPath:String, sampledGts: RDD[Genotype], sampledGtsESP: RDD[Variant]) {

     val usefulDataESP = sampledGtsESP.map(p => (p.getContig.getContigName, p.getStart, p.getEnd, p.getReferenceAllele, p.getAlternateAllele))
     val reduced_VariantsESP = usefulDataESP.flatMap(p => Seq((p._1, p._2, p._3, p._4, p._5)))
     val joinESP      = reduced_VariantsESP.map({a  => ( (a._1, a._2, a._3, a._4, a._5), 1 )}).cache()
    
     val usefulData = sampledGts.map(p => (p.getVariant.getContig.getContigName,p.getVariant.getStart, p.getVariant.getEnd, p.getVariant.getReferenceAllele,p.getVariant.getAlternateAllele,p.getAlleles.get(0),p.getAlleles.get(1),if(p.getAlleles.get(0) == GenotypeAllele.Alt ||  p.getAlleles.get(1) == GenotypeAllele.Alt ) 1.0 else 0.0 ))
     
    val reduced_Variants = usefulData.flatMap(p => Seq((p._1, p._2, p._3, p._4, p._5, p._8))).filter({ a => (a._6 == 1.0)})

    val filterall   = reduced_Variants.map({ a => ( (a._1, a._2, a._3, a._4, a._5), 1 ) }).cache()

    import org.apache.spark.SparkContext._
    val joinedset = filterall.join(joinESP)

    val numvariants = joinedset.count() 
    val outputstr = s"Number of Variants: $numvariants"
    val outputdata:RDD[String] = sc.parallelize(List(outputstr))
    outputdata.saveAsTextFile(outputPath)
    
    val joinedreduce  = joinedset.map({case(a,b)=> (a,b._1)}).reduceByKey(_+_).cache()
    val numvariantsred = joinedreduce.count()
    
    val outputstrred = s"Number of VariantsRed: $numvariantsred"
    val outputdatared:RDD[String] = sc.parallelize(List(outputstrred))
    outputdatared.saveAsTextFile(outputPath + "FinalResult")
  

  }



def normalizejoin(sc: org.apache.spark.SparkContext, outputPath:String, sampledGts: RDD[Genotype], sampledGtsESP: RDD[Variant]) {

     val usefulDataESP = sampledGtsESP.map(p => (p.getContig.getContigName, p.getStart, p.getReferenceAllele, p.getAlternateAllele))
     val reduced_VariantsESP = usefulDataESP.flatMap(p => Seq((p._1, p._2, p._3, p._4)))
     val joinESP    = reduced_VariantsESP.map({a  => ( (a._1, a._2, a._3, a._4), 1 )}).cache()

     val usefulData = sampledGts.map(p => (p.getVariant.getContig.getContigName,p.getVariant.getStart, p.getVariant.getReferenceAllele,p.getVariant.getAlternateAllele,p.getAlleles.get(0),p.getAlleles.get(1)))
     
    val reduced_Variants = usefulData.flatMap(p => Seq((p._1, p._2, p._3, p._4, p._5), (p._1, p._2, p._3, p._4,p._6))).flatMap(chooseAllele)

    val filterall = reduced_Variants.map({ a => ( (a._1, a._2, a._3, a._4), 1 ) }).reduceByKey(_+_).cache()

    import org.apache.spark.SparkContext._
    val joinedset = filterall.join(joinESP)

    val numvariants = joinedset.count()

    val outputstrred = s"Number of VariantsRed: $numvariants"
    val outputdatared:RDD[String] = sc.parallelize(List(outputstrred))
    outputdatared.saveAsTextFile(outputPath + "FinalResult")


}


}



object Query1 {

def main(args: Array[ String]){

 val conf = new SparkConf().setMaster("spark://p4xen7:7077")
                           .setAppName("Query1")
                           .set("spark.executor.memory", "120g")
                           .set("spark.driver.memory", "120g")
                           .set("spark.local.dir","/datadisk1/spark,/datadisk2/spark,/datadisk3/spark,/datadisk4/spark")
                           .set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
                           .set("spark.kryoserializer.buffer.mb", "20")
                           .set("spark.kryo.referenceTracking", "true")
                           .set("spark.kryo.registrator", "org.bdgenomics.adam.serialization.ADAMKryoRegistrator")
 
import org.bdgenomics.adam.rdd.ADAMContext
val sc = new SparkContext(conf)
val ac = new ADAMContext(sc)

import System.{currentTimeMillis => _time}
def profile[R](code: => R, t: Long = _time) = (code, _time - t)

// usage:
//val (result, time) = profile { /* block of code to be profiled*/ }
//val (result2, time2) = profile methodToBeProfiled(foo)

def hu(s:String) = s"hdfs://10.0.20.195:9000/sandbox/$s"
def hu2(s:String) = s"hdfs://10.0.20.195:9000/sandbox/tempfiles/$s"


//$$$$$$$$$$$$$$$$$$$$$ Test 1 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//val gts:RDD[Genotype] = ac.loadGenotypes(hu("ALL.chr7.phase3_shapeit2_mvncall_integrated_v4.20130502.genotypes.vcf.adam"))
//val sampledGtsESP:RDD[Variant] = ac.loadVariants(hu("ESP6500SI-V2-SSA137.GRCh38-liftover.chr7.snps_indels.vcf.adam"))
//val chromo = "7"
//val start = 2792875 
//val end   = 4852328 
//val outputPath="/sandbox/tempfiles/query3_chr7V1"
//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

//$$$$$$$$$$$$$$$$$$$$ Test 2 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
val sampledGts:RDD[Genotype] = ac.loadGenotypes(hu("ALL.chr8.phase3_shapeit2_mvncall_integrated_v4.20130502.genotypes.vcf.adam")).persist()
val sampledGtsESP:RDD[Variant] = ac.loadVariants(hu("ESP6500SI-V2-SSA137.GRCh38-liftover.chr8.snps_indels.vcf.adam")).persist()
val chromo = "8"
//val start = 55086678
//val end   = 55279262

val outputPath="/sandbox/tempfiles/query3_chr8full_FullJoinNormalizedV1"
//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


import org.bdgenomics.adam.models._
import org.bdgenomics.adam.rdd.variation._

//val pt          = new ReferenceRegion(chromo,start,end);
//val genogts     = new GenotypeRDDFunctions(gts)
//val sampledGts  = genogts.filterByOverlappingRegion(pt)

val (result,time) = profile {

val allcountobj = new AlleleJoin
allcountobj.normalizejoin(sc,outputPath, sampledGts, sampledGtsESP)
//allcountobj.denormalizejoin(sc,outputPath, sampledGts, sampledGtsESP)

}//time profiling

val outputstr = s"ProcessingTime: $time"
val outputdata:RDD[String] = sc.parallelize(List(outputstr))
    outputdata.take(1).foreach(println)

}//main
}//Object
