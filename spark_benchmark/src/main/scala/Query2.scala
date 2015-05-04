

import scala.sys.process._
import scala.io.Source
import System.{currentTimeMillis => _time}
import scala.math.random

import org.apache.hadoop.mapreduce.Job

import org.apache.spark._
import org.apache.spark.api.java.JavaRDD
import org.apache.spark.{ Logging, SparkContext }
import org.apache.spark.rdd.RDD
import parquet.hadoop.metadata.CompressionCodecName
//import org.kohsuke.args4j.Argument

import org.bdgenomics.adam.rdd.ADAMContext._
import org.bdgenomics.formats.avro._
import org.bdgenomics.formats.avro.{ Genotype, GenotypeAllele }
import org.bdgenomics.adam.models.VariantContext
import org.bdgenomics.adam.rdd.ADAMContext
import org.bdgenomics.adam.models._
import org.bdgenomics.adam.rdd.variation._
import org.bdgenomics.formats.avro.{DatabaseVariantAnnotation, Variant, Genotype, FlatGenotype}


class AlleleCountHelper extends Serializable {

	def chooseAllele(x: (String, java.lang.Long, String, String, GenotypeAllele,String)) =
			x match {
			case (chr, position, refAllele, varAllele, GenotypeAllele.Ref, pop) => Some(chr, position, refAllele, pop )
			case (chr, position, refAllele, varAllele, GenotypeAllele.Alt, pop) => Some(chr, position, varAllele, pop )
			case _ => None
	}

	def countGroupedAlleles(outputPath: String, adamVariants: RDD[Genotype],bPanel:org.apache.spark.broadcast.Broadcast[Map[String,String]]) {

		val usefulData = adamVariants.map(p => (p.getVariant.getContig.getContigName,p.getVariant.getStart, p.getVariant.getReferenceAllele,p.getVariant.getAlternateAllele,p.getAlleles.get(0),p.getAlleles.get(1),bPanel.value.getOrElse(p.getSampleId,"nopop")))

				val reduced_Variants = usefulData.flatMap(p => Seq((p._1, p._2, p._3, p._4, p._5,p._7), (p._1, p._2, p._3, p._4, p._6,p._7)))

				val alleles = reduced_Variants.flatMap(chooseAllele)
				
        import org.apache.spark.SparkContext._
				val sortedall = alleles.map(p =>(p,1)).reduceByKey(_+_)
				//val sortedall = alleles.groupBy(identity).sortBy(a => a._2, true) 

				sortedall.map { case (a, b) => "%s\t%s\t%s\t%s\t%d".format(a._1, a._2, a._3, a._4, b) }.saveAsTextFile(outputPath)

	}//countGroupedAlleles
}//AlleleCountHelper


object Query2 {

	def main(args: Array[ String]){

		val conf = new SparkConf().setMaster("spark://p4xen7:7077")
				.setAppName("Query2")
				.set("spark.executor.memory", "125g")
				.set("spark.driver.memory", "125g")
				.set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
				.set("spark.kryoserializer.buffer.mb", "20")
				.set("spark.kryo.referenceTracking", "true")
				.set("spark.kryo.registrator", "org.bdgenomics.adam.serialization.ADAMKryoRegistrator")

				val sc = new SparkContext(conf)

		def profile[R](code: => R, t: Long = _time) = (code, _time - t)

		// usage:
		//val (result, time) = profile { /* block of code to be profiled*/ }
		//val (result2, time2) = profile methodToBeProfiled(foo)

		def hu(s:String) = s"hdfs://10.0.20.195:9000/benchmark/$s"
		def hu2(s:String) = s"hdfs://10.0.20.195:9000/benchmark/tempfiles/$s"

		// MAIN Program function
		val (result,time) = profile {

			val ac = new ADAMContext(sc)

			//PROGRAM INPUTS
			//val sampledGts:RDD[Genotype] = ac.loadGenotypes(hu2("20k-sample.adam"))
			//val gts:RDD[Genotype]  = ac.loadGenotypes(hu2("20k.adam"))

			//$$$$$$$$$$$$$$$$$$$$$$$$$ TEST 1 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
			//val gts:RDD[Genotype]  = ac.loadGenotypes(hu("ALL.chr8.phase3_shapeit2_mvncall_integrated_v4.20130502.genotypes.vcf.adam")).cache()
			//val outputPath="/sandbox/tempfiles/expquery2_c8_short"
			//val chromo = "8"
			//val start = 56986398 
			//val end   = 56986460
			//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

			//$$$$$$$$$$$$$$$$$$$$$$$$$ TEST 2 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
			//val gts:RDD[Genotype]  = ac.loadGenotypes(hu("ALL.chr8.phase3_shapeit2_mvncall_integrated_v4.20130502.genotypes.vcf.adam")).cache()
			//val outputPath="/sandbox/tempfiles/diffkeyquery2_c8_longV2"
			//val chromo = "8"
			//val start = 2792875
			//val end   = 4852328
			//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

			//$$$$$$$$$$$$$$$$$$$$$$$$$ TEST 3 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
			val gts:RDD[Genotype]  = ac.loadGenotypes(hu("ALL.chr7.phase3_shapeit2_mvncall_integrated_v4.20130502.genotypes.vcf.adam")).cache()
			val outputPath="/sandbox/tempfiles/expquery2_c7_medium"
			val chromo = "7"
			val start = 55086678 
			val end   = 55279262
			//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
      val panelFile = s"/home/bio/testdata/populations.tsv"

			import org.bdgenomics.adam.models._
			import org.bdgenomics.adam.rdd.variation._

			val pt          = new ReferenceRegion(chromo,start,end);
			val genogts     = new GenotypeRDDFunctions(gts)
			val sampledGts  = genogts.filterByOverlappingRegion(pt)


			def extract(filter: (String, String) => Boolean= (s, t) => true) = Source.fromFile(panelFile).getLines().map( line => {
				val toks = line.split("\t").toList
						toks(0) -> toks(1)
			}).toMap.filter( tup => filter(tup._1, tup._2) )

			def panel: Map[String,String] =
			extract((sampleID: String, pop: String) => (true))
			val bPanel = sc.broadcast(panel)

			val allcountobj = new AlleleCountHelper
			allcountobj.countGroupedAlleles(outputPath, sampledGts, bPanel)
			
		}//time profiling

	}//main
}//object 


