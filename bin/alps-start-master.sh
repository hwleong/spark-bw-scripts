#!/bin/bash

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

if [ -z $SPARK_MASTER_HOST ]
then
    echo Spark module is not loaded. 
    echo Please load Spark module. 
    exit 1
else
    SPARK_MASTER_HOSTIP=`grep $SPARK_MASTER_HOST /etc/hosts | awk {'print $1'}`
fi

echo Starting Spark Master on $SPARK_MASTER_HOST \(URL: http://$SPARK_MASTER_HOSTIP:8080\)...

aprun -n 1 -b -- "${SPARK_SCRIPTS}/sbin"/start-master.sh &


