#!/bin/bash

aprun -n 1 -b -- "${SPARK_HOME}/bin/run-example" --master spark://$SPARK_MASTER_HOST:7077 SparkPi 100
