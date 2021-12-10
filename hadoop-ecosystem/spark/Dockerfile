ARG debian_buster_image_tag=11-jdk-buster
FROM openjdk:${debian_buster_image_tag}

# -- Layer: Apache Spark
# https://www.kdnuggets.com/2020/07/apache-spark-cluster-docker.html

ARG shared_workspace=/opt/workspace
ARG SPARK_VERSION=3.2.0
ARG HADOOP_VERSION=3.2
ARG SCALA_VERSION=2.13
ARG spark_master_web_ui=8080
ARG spark_worker_web_ui=8081


#https://search.maven.org/search?q=spark-sql-kafka
#https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.2.0/spark-sql-kafka-0-10_2.12-3.2.0.jar
#https://repo1.maven.org/maven2/org/apache/spark/spark-streaming-kafka-0-10-assembly_2.12/3.2.0/spark-streaming-kafka-0-10-assembly_2.12-3.2.0.jar

RUN mkdir -p ${shared_workspace} && \
    apt-get update -y && \
    apt-get install -y curl wget python3 && \
    wget --debug -O spark.tgz "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    tar -xf spark.tgz && \
    mv "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" /usr/bin/ && \
    mkdir "/usr/bin/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}/logs" && \
    rm spark.tgz
#-scala${SCALA_VERSION}
# -- Runtime

RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get autoclean && \
    rm -Rf /tmp/*

ENV SHARED_WORKSPACE=${shared_workspace}
ENV SPARK_HOME="/usr/bin/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}"
ENV SPARK_MASTER_HOST=spark-master
ENV SPARK_MASTER_PORT=7077
ENV PYSPARK_PYTHON=python3
EXPOSE ${spark_master_web_ui} ${SPARK_MASTER_PORT} ${spark_worker_web_ui}
# in case PYSPARK_PYTHON not equals to PYSPARK_DRIVER_PYTHON

RUN echo '#!/bin/bash \
          \nbin/spark-class org.apache.spark.deploy.master.Master >> logs/spark-master.out' \
          > /run_spark-master.sh && \
    chmod +x /run_spark-master.sh

RUN echo '#!/bin/bash \
          \nbin/spark-class org.apache.spark.deploy.worker.Worker spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT >> logs/spark-worker.out' \
          > /run_spark-worker.sh && \
    chmod +x /run_spark-worker.sh

WORKDIR ${SPARK_HOME}
VOLUME ${shared_workspace}
CMD ["bash"]