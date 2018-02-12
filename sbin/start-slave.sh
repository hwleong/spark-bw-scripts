#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Starts a slave instance on each machine specified in the conf/slaves file.

. "${SPARK_HOME}/sbin/spark-config.sh"
. "${SPARK_HOME}/bin/load-spark-env.sh"

# Find the port number for the master
if [ "$SPARK_MASTER_PORT" = "" ]; then
  SPARK_MASTER_PORT=7077
fi

# Launch the slaves
"${SPARK_HOME}/sbin/start-slave.sh" "spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT"

# Check status of SPARK slave
SPARK_SLAVE_STATUS=`${SPARK_HOME}/sbin/spark-daemon.sh status org.apache.spark.deploy.worker.Worker 1`
while [ -n "$SPARK_SLAVE_STATUS" ]
do
    echo ${SPARK_SLAVE_STATUS}. >/dev/null
    SPARK_SLAVE_STATUS=`${SPARK_HOME}/sbin/spark-daemon.sh status org.apache.spark.deploy.worker.Worker 1 | grep "is running"`
    sleep 5
done
