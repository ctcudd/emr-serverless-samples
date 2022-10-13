# MIT No Attribution

# Copyright 2021 Amazon.com, Inc. or its affiliates

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import os
import sys
from datetime import date
from pyspark.sql import SparkSession
from mypackage import extreme_weather
import function

if __name__ == "__main__":
    """
    Usage: extreme-weather [year]

    Displays extreme weather stats (highest temperature, wind, precipitation) for the given, or latest, year.
    """
    spark = SparkSession.builder.appName("ExtremeWeather").getOrCreate()

    if len(sys.argv) > 1:
        bucket = sys.argv[1]
    else:
        bucket = "emr-serverless-full-emrserverlesslogbucket-1f4n5ib73bo02"


    dir_path = os.path.dirname(os.path.realpath(__file__))
    print(f"HelloWorld from {dir_path}/app.py")

    # module imported through --archives
    extreme_weather.helloWorld()
    extreme_weather.numpy_test()

    # file imported through --py-files
    function.helloWorld()

    # dynamically added file
    sc = spark.sparkContext
    sc.addFile(f"s3://{bucket}/code/pyspark/file.py")
    import file
    file.helloWorld()

    # df = spark.read.csv(f"s3://noaa-gsod-pds/{year}/", header=True, inferSchema=True)
    # print(f"The amount of weather readings in {year} is: {df.count()}\n")
    #
    # print(f"Here are some extreme weather stats for {year}:")
    # stats_to_gather = [
    #     {"description": "Highest temperature", "column_name": "MAX", "units": "°F"},
    #     {
    #         "description": "Highest all-day average temperature",
    #         "column_name": "TEMP",
    #         "units": "°F",
    #     },
    #     {"description": "Highest wind gust", "column_name": "GUST", "units": "mph"},
    #     {
    #         "description": "Highest average wind speed",
    #         "column_name": "WDSP",
    #         "units": "mph",
    #     },
    #     {
    #         "description": "Highest precipitation",
    #         "column_name": "PRCP",
    #         "units": "inches",
    #     },
    # ]
    #
    # for stat in stats_to_gather:
    #     max_row = extreme_weather.findLargest(df, stat["column_name"])
    #     print(
    #         f"  {stat['description']}: {max_row[stat['column_name']]}{stat['units']} on {max_row.DATE} at {max_row.NAME} ({max_row.LATITUDE}, {max_row.LONGITUDE})"
    #     )
