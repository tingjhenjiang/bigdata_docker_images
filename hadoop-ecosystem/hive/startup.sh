#!/bin/bash

hadoop fs -mkdir       /tmp
hadoop fs -mkdir -p    /user/hive/warehouse
hadoop fs -chmod g+w   /tmp
hadoop fs -chmod g+w   /user/hive/warehouse

cp $HIVE_HOME/conf/hive-site.xml /opt/workspace/docker_build_compose/hadoop-ecosystem/hive/conf_configured/
cd $HIVE_HOME/bin
./hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000 --hiveconf hive.server2.enable.doAs=false --hiveconf hive.root.logger=INFO,console