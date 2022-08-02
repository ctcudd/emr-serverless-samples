import sbt._

object Dependencies {

  object Version {
    val spark = "3.2.0"
    val scalatest = "3.0.3"
    val typesafe_config = "1.4.2"
    val typesafe_akka = "2.6.19"
    val typesafe_akka_http = "10.2.9"
    val hadoop_aws = "3.2.1"
    val scalaj_http = "2.4.2"
    val scala_graph_core = "1.13.1"
    val scala_graph_json = "1.13.0"
    val irvingc_spark_dbscan = "0.2.0"
    val google_maps = "2.0.0"
    val circe = "0.14.1"
    val circe_java8 = "0.11.1"
    val geojson = "1.14"
    val protobuf = "3.19.4"
    val cassandra = "3.11.1"
  }

  val sparkFriendlyJacksonVersions = Seq(
    "com.fasterxml.jackson.core" % "jackson-core" % "2.12.6",
    "com.fasterxml.jackson.core" % "jackson-databind" % "2.12.6.1"
  )

  val emrVersions = Seq(
    "org.apache.hadoop" % "hadoop-client-api" % Version.hadoop_aws,
    "org.apache.hadoop" % "hadoop-client-runtime" % Version.hadoop_aws,
    "com.google.guava" % "guava" % "23.0"
  )

  object Library {

    val common = Seq(
      "org.apache.hadoop" % "hadoop-aws" % Version.hadoop_aws % "provided",
      "org.apache.spark" %% "spark-core" % Version.spark % "provided",
      "org.apache.spark" %% "spark-hive" % Version.spark % "provided",
      "org.apache.spark" %% "spark-sql" % Version.spark % "provided",
      "org.apache.spark" %% "spark-mllib" % Version.spark % "provided",
      "com.typesafe" % "config" % Version.typesafe_config
    )

    val analytics = Seq(
      "org.scalaj" %% "scalaj-http" % Version.scalaj_http,
      "org.scala-graph" %% "graph-core" % Version.scala_graph_core,
      "org.scala-graph" %% "graph-json" % Version.scala_graph_json,
      "com.typesafe.akka" %% "akka-actor" % Version.typesafe_akka,
      "com.typesafe.akka" %% "akka-stream" % Version.typesafe_akka,
      "com.typesafe.akka" %% "akka-http" % Version.typesafe_akka_http,
//      "com.irvingc.spark" %% "dbscan-on-spark" % Version.irvingc_spark_dbscan
    )

    val geo = Seq(
      "com.google.maps" % "google-maps-services" % Version.google_maps,
      "com.google.protobuf" % "protobuf-java" % Version.protobuf % "protobuf",
      "com.thesamet.scalapb" %% "scalapb-runtime" % scalapb.compiler.Version.scalapbVersion % "protobuf",
      "com.datastax.cassandra" % "cassandra-driver-mapping" % Version.cassandra,
      "de.grundid.opendatalab" % "geojson-jackson" % Version.geojson
    )

    val circe = Seq(
      "io.circe" %% "circe-core" % Version.circe,
      "io.circe" %% "circe-generic" % Version.circe,
      "io.circe" %% "circe-generic-extras" % Version.circe,
      "io.circe" %% "circe-parser" % Version.circe,
      "io.circe" %% "circe-java8" % Version.circe_java8
    )
  }

  object Testing {

    val common = Seq(
      "org.scalactic" %% "scalactic" % Version.scalatest % "test",
      "org.scalatest" %% "scalatest" % Version.scalatest % "test",
      "org.scalamock" %% "scalamock" % "4.0.0"
    )
  }
}
