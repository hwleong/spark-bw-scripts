#!/bin/bash

usage()
{
    echo usage: ./install.sh install_prefix_path
    echo Example: ./install.sh /usr/local
}

while getopts :h OPT
do
    case $OPT in
        h)
            usage
            exit 1
            ;;
        \?)
            usage
            exit 1
            ;;
    esac
done

if [ $# != 1 ]
then
    echo Please specify an installation path. 
    echo
    usage
    exit 1
else
    INSTALL_DIR=$1
    if [ ! -d $1 ]
    then
        echo Creating $INSTALL_DIR
        echo "mkdir -p $INSTALL_DIR"
        mkdir -p $INSTALL_DIR
        if [ $? != 0 ]
        then
            echo No permission to create $INSTALL_DIR directory. 
            exit 1
        fi
    fi
    if [ -w $INSTALL_DIR ]
    then
        echo Installing wrapper scripts to $INSTALL_DIR directory. 
    else
        echo No permission to install to $INSTALL_DIR
        exit 1
    fi
fi    

echo
echo "rsync -ravl bin sbin $INSTALL_DIR"
rsync -ravl bin sbin $INSTALL_DIR

echo
echo Installing module file...
if [ ! -d $INSTALL_DIR/modulefiles ]
then
    echo "mkdir $INSTALL_DIR/modulefiles"
    mkdir $INSTALL_DIR/modulefiles
fi

cat > $INSTALL_DIR/modulefiles/spark-2.1.1 << EOF
#%Module
#
# spark ver. 2.1.1 for Blue Waters
#

proc ModulesHelp { } {
    puts stderr {

Description
===========
Spark implementation for Blue Waters via Shifter.
This module can only be loaded in a PBS job environment. 

In order to use this module, please submit job with the following resource:
$ qsub -l nodes=3:ppn=16,gres=shifter16 -v UDI=lgerhardt/spark-2.1.1:v1 [-I|<jobscript>]

At least three compute nodes are required: 
one Spark master
at least one Spark slave
one Spark submission host
    }
}

module-whatis {Spark implementation for Blue Waters via Shifter. }

if { [ info exists env(PBS_NODEFILE) ] } {
    setenv SPARK_MASTER_HOST [ exec cat \$env(PBS_NODEFILE) | uniq | awk {{printf "nid%05d\n",\$1}} | head -1 ]
} else {
    puts stderr "Spark Module cannot be loaded without a PBS job. "
    exit 1
}

setenv SPARK_HOME /usr/local/bin/spark-2.1.1-bin-hadoop2.7
setenv SPARK_SCRIPTS $INSTALL_DIR
setenv SPARK_CONF_DIR \$env(SPARK_SCRIPTS)/conf
setenv CRAY_ROOTFS SHIFTER

prepend-path PATH \$env(SPARK_SCRIPTS)/bin

if { [ info exists env(JAVA_HOME) ] } {
    unsetenv JAVA_HOME
}
EOF

echo
echo "Please add $INSTALL_DIR/modulefiles to your \$MODULEPATH environment"
echo "module use $INSTALL_DIR/modulefiles"
module use $INSTALL_DIR/modulefiles
echo MODULEPATH=$MODULEPATH
export MODULEPATH

echo
echo Setting up default configurations for Blue Waters...
if [ ! -d $INSTALL_DIR/conf ]
then
    echo "mkdir $INSTALL_DIR/conf"
    mkdir $INSTALL_DIR/conf
fi
cp conf/spark-env.sh $INSTALL_DIR/conf
echo SPARK_WORKER_DIR=$INSTALL_DIR/work >> $INSTALL_DIR/conf/spark-env.sh
echo SPARK_CONF_DIR=$INSTALL_DIR/conf >> $INSTALL_DIR/conf/spark-env.sh
echo SPARK_LOG_DIR=$HOME/scratch/spark >> $INSTALL_DIR/conf/spark-env.sh

echo
echo Installation completed. 
