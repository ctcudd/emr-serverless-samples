package org.example

import java.io.{BufferedWriter, OutputStreamWriter}
import java.net.URI
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{FileStatus, FileSystem, Path}
import org.apache.spark.sql.{SaveMode, SparkSession}
import java.util.Date

object JsonToParquet {
  def printPath(path: String, configuration: Configuration, debug: Boolean = false): Unit = {
    var fileSystem: FileSystem = null
    var fileStatuses: Array[FileStatus] = null
    try {
      fileSystem = FileSystem.get(URI.create(path), configuration)
      fileStatuses = fileSystem.globStatus(new Path(path))
      println(s"found: ${fileStatuses.length} files at path: ${path}")
      fileStatuses.foreach(c => println(c.toString))
    } catch {
      case t: Throwable =>
        println(s"Exception: ${t.getMessage} for path: ${path}")
        if(debug) t.printStackTrace(System.out)
    }
  }

  def jsonToParquet(session: SparkSession, inputPath: String, outputPath: String): Unit ={
    session.read
      .json(inputPath)
      .repartition(1)
      .write
      .mode(SaveMode.Overwrite)
      .parquet(outputPath)
  }

  def main(args: Array[String]): Unit = {

    val dateFormat = new java.text.SimpleDateFormat("yyyy-MM-dd")

    var date = new Date()
    var bucketName = args.lift(0).orNull
    var dateString = args.lift(1).orNull
    var debug = Option(args.lift(2).orNull).exists(_.toBoolean)

    if(null != dateString) {
      try {
        date = dateFormat.parse(dateString)
      } catch {
        case t: Throwable =>
          println(s"Exception: ${t.getMessage} for dateString: ${dateString}")
          if(debug) t.printStackTrace(System.out)
      }
    }

    implicit val session: SparkSession = SparkSession
      .builder()
      .getOrCreate()

    val context = session.sparkContext

    println("appName:" + context.appName);
    println("deployMode:" + context.deployMode);
    println("master:" + context.master);
    println("Spark Version:" + context.version)
    println("Hadoop version: " + org.apache.hadoop.util.VersionInfo.getVersion)
    println("BucketName: " + bucketName)
    println("Date: " + dateFormat.format(date))
    var inputPath = s"${bucketName}/input/${dateFormat.format(date)}/*.gz"
    var outputPath = s"${bucketName}/output/${dateFormat.format(date)}/"

    val configuration = new Configuration(context.hadoopConfiguration)
    if (debug) {
      Configuration.dumpConfiguration(configuration, new BufferedWriter(new OutputStreamWriter(System.out)))
      Utils.dumpEnvVars()
      Utils.dumpSysProps()
    }

    for (f <- S3Schemes.values) {
      val cfgKey = s"fs.${f}.impl"
      val cfgVal = configuration.get(cfgKey)
      println(s"${cfgKey}: ${cfgVal}")

      printPath(s"${f}://${inputPath}", configuration, debug)
      jsonToParquet(session, s"${f}://${inputPath}", s"${f}://${outputPath}${f}/")
    }
  }
}
