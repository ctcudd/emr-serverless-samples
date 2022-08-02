package org.example

import scala.language.implicitConversions

object S3Schemes extends Enumeration {
  protected case class Val(val key: String, val secret: String) extends super.Val {
    def getKey:String = key
    def getSecret:String = key
  }
  implicit def valueToS3SchemeVal(x: Value) = x.asInstanceOf[Val]
  val s3 = Val("fs.s3.access.key","fs.s3.secret.key")
  val s3a = Val("fs.s3a.access.key","fs.s3a.secret.key")
  val s3n = Val("fs.s3n.awsAccessKeyId","fs.s3n.awsSecretAccessKey")
}
