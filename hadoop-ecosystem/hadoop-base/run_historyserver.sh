#!/bin/bash

ln -s /hadoop/dfs/specificmount $YARN_CONF_yarn_timeline___service_leveldb___timeline___store_path
$HADOOP_HOME/bin/yarn --config $HADOOP_CONF_DIR historyserver