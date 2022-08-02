import sbt._
import Keys._
import sbtassembly._
import sbtassembly.AssemblyKeys._

object Assembly {

  private[this] object Properties {
    def unapply(name: String) = Some(name) filter (_.endsWith(".properties"))
  }

  private[this] object Configuration {
    def unapply(name: String) = Some(name) filter (_.endsWith(".conf"))
  }

  private[this] type Strategy = PartialFunction[String, MergeStrategy]

  private[this] val configuration: Strategy = {
    case PathList("META-INF", "io.netty.versions.properties") => MergeStrategy.concat
    case PathList("META-INF", "aop.xml")                      => AOPMerge.strategy
    case Configuration(name)                                  => MergeStrategy.concat
    case Properties(name)                                     => MergeStrategy.concat
    case "logback.xml"                                        => MergeStrategy.first
  }

  private[this] val default: Strategy = {
    case other => MergeStrategy.defaultMergeStrategy(other)
  }

  val analyticsStrategy: Strategy = {
    case PathList("javax", xs @ _*)                           => MergeStrategy.first
    case PathList("org", "aopalliance", xs @ _*)              => MergeStrategy.first
    case PathList("org", "apache", xs @ _*)                   => MergeStrategy.first
    case PathList("org", "slf4j", xs @ _*)                    => MergeStrategy.first
    case PathList(ps @ _*) if ps.last endsWith ".proto"       => MergeStrategy.first
    case PathList("module-info.class")                        => MergeStrategy.discard
    case PathList(ps @ _*) if ps.last endsWith ".html"        => MergeStrategy.discard
  }

  val analytics = Seq(
    assembly/assemblyMergeStrategy := configuration orElse analyticsStrategy orElse default
  )

  val protobuf = Seq(
    assembly/assemblyMergeStrategy := configuration orElse analyticsStrategy orElse default
  )

}
