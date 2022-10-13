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

from pyspark.sql import DataFrame, Row
from pyspark.sql import functions as F
import os
import numpy as np


def helloWorld():
    dir_path = os.path.dirname(os.path.realpath(__file__))
    print(f"HelloWorld from {dir_path}/extreme_weather.py")


def numpy_test():
    x = np.random.random(10)
    print(f"created with numpy: {x}")


def findLargest(df: DataFrame, col_name: str) -> Row:
    """
    Find the largest value in `col_name` column.
    Values of 99.99, 999.9 and 9999.9 are excluded because they indicate "no reading" for that attribute.
    While 99.99 _could_ be a valid value for temperature, for example, we know there are higher readings.
    """
    return (
        df.select(
            "STATION", "DATE", "LATITUDE", "LONGITUDE", "ELEVATION", "NAME", col_name
        )
            .filter(~F.col(col_name).isin([99.99, 999.9, 9999.9]))
            .orderBy(F.desc(col_name))
            .limit(1)
            .first()
    )
