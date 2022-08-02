package org.example

import scala.collection.JavaConverters._
import scala.language.implicitConversions
import org.apache.spark.sql.SparkSession
object Utils {

  def initiateSpark(master: String = null, appName: String = "spark-samples-scala"): SparkSession = {
    val sparkBuilder = SparkSession.
      builder.
      appName(appName)
    if (master != null) {
      sparkBuilder.master(master)
    }
    val spark = sparkBuilder.getOrCreate()
    spark.conf.set("spark.debug.maxToStringFields", "5000")
    spark
  }
  def dumpEnvVars(): Unit ={
    val environmentVars = System.getenv().asScala
    for ((k,v) <- environmentVars) println(s"key: $k, value: $v")
  }
  def dumpSysProps(): Unit ={
    val properties = System.getProperties().asScala
    for ((k,v) <- properties) println(s"key: $k, value: $v")
  }
}
