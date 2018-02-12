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

# Find the port number for the master

qstat -f $PBS_JOBID | grep "^\sUDI=lgerhardt/spark-2.1.1:v1" > /dev/null
if [ $? != 0 ]
then
    echo Spark container "lgerhardt/spark-2.1.1:v1" is not setup on compute nodes
    echo Please re-submit job with "-v lgerhardt/spark-2.1.1:v1" arguments.
    exit 1
fi

if [ "$CRAY_ROOTFS" != "SHIFTER" ]
then
    echo \$CRAY_ROOTFS is not set to "SHIFTER"
    echo Please set \$CRAY_ROOTFS to "SHIFTER" before using this script.
    exit 1
fi

if [ "$SPARK_MASTER_PORT" = "" ]; then
  export SPARK_MASTER_PORT=7077
fi

if [ $PBS_NUM_NODES -lt 3 ]
then
    echo "\$PBS_NUM_NODES is less than 3"
    echo "At least 3 compute nodes are needed for Spark. "
    exit 1
fi

SPARK_NUM_SLAVE_HOSTS=`expr $PBS_NUM_NODES - 2`

BATCH_JOBID=`echo $PBS_JOBID | sed 's/\.jyc//g'`

for apid in `apstat -r | grep batch:$BATCH_JOBID | grep "^A" | awk {'print $3'}`
do
    apstat -A $apid -a -v | grep "\sCmd" | grep start-master.sh >/dev/null
    if [ $? == 0 ]
    then
        SPARK_MASTER_STARTED=1
        break
    fi
done

if [ -z $SPARK_MASTER_STARTED ]
then
    echo Spark master is not started. 
    echo Please start a Spark master first before starting Spark slaves. 
    exit 1
fi

# Launch the slaves
echo Starting Spark slaves...
aprun -n ${SPARK_NUM_SLAVE_HOSTS} -cc none -N 1 -b -- ${SPARK_SCRIPTS}/sbin/start-slave.sh &
