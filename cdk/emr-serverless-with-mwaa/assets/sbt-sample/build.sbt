import sbt._
import Keys.{dependencyOverrides, _}
import Dependencies._

ThisBuild / version := "0.0.1-SNAPSHOT"

ThisBuild / scalaVersion := "2.12.15"

lazy val root = (project in file("."))
  .settings(
    name := "sbt-sample",
    idePackagePrefix := Some("org.example"),
    Assembly.analytics,
    libraryDependencies ++= (Library.common ++ Library.analytics ++ Library.geo ++ Library.circe ++ Testing.common),
    dependencyOverrides ++= sparkFriendlyJacksonVersions ++ emrVersions
  )
