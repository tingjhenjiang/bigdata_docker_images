ARG debian_buster_image_tag=8-jdk-buster
FROM openjdk:${debian_buster_image_tag}

# -- Layer: hadoop-base

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      dos2unix \
      net-tools \
      curl \
      wget \
      netcat \
      gnupg \
      libsnappy-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://dist.apache.org/repos/dist/release/hadoop/common/KEYS

RUN gpg --import KEYS

ARG HADOOP_VERSION=3.2.2
ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV HADOOP_URL=https://www.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz

#COPY hadoop-$HADOOP_VERSION.tar.gz /tmp/hadoop.tar.gz

RUN set -x \ 
    #&& curl -fSL "$HADOOP_URL" -o /tmp/hadoop.tar.gz \
    && wget "$HADOOP_URL" -O /tmp/hadoop.tar.gz \
    && curl -fSL "$HADOOP_URL.asc" -o /tmp/hadoop.tar.gz.asc \
    && gpg --verify /tmp/hadoop.tar.gz.asc \
    && tar -xvf /tmp/hadoop.tar.gz -C /opt/ \
    && rm /tmp/hadoop.tar.gz*

RUN ln -s /opt/hadoop-$HADOOP_VERSION/etc/hadoop /etc/hadoop

RUN mkdir /opt/hadoop-$HADOOP_VERSION/logs

RUN mkdir /hadoop-data

ENV HADOOP_HOME=/opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=/etc/hadoop
ENV MULTIHOMED_NETWORK=1
ENV USER=root
ENV PATH=$HADOOP_HOME/bin/:$PATH

ADD entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh && \
    dos2unix /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

RUN mkdir /hadoop-runscripts
ADD run_namenode.sh /hadoop-runscripts/run_namenode.sh
ADD run_datanode.sh /hadoop-runscripts/run_datanode.sh
ADD run_nodemanager.sh /hadoop-runscripts/run_nodemanager.sh
ADD run_resourcemanager.sh /hadoop-runscripts/run_resourcemanager.sh
ADD run_historyserver.sh /hadoop-runscripts/run_historyserver.sh
RUN find /hadoop-runscripts -type f -print0 | xargs -0 -n 1 -P 4 dos2unix && \
    find /hadoop-runscripts -type f -iname "*.sh" -exec chmod +x {} \;
RUN mkdir /hadoop/dfs/specificmount -p
RUN useradd -m -U -g root hdfs

# -- Layer: namenode

HEALTHCHECK CMD curl -f http://localhost:9870/ || exit 1

ENV HDFS_CONF_dfs_namenode_name_dir=file:///hadoop/dfs/name
#RUN mkdir -p /hadoop/dfs/name
#RUN ln -s /hadoop/dfs/specificmount /hadoop/dfs/name
#EXPOSE 9870

# -- Layer: datanode

HEALTHCHECK CMD curl -f http://localhost:9864/ || exit 1

ENV HDFS_CONF_dfs_datanode_data_dir=file:///hadoop/dfs/data
#RUN mkdir -p /hadoop/dfs/data
#RUN ln -s /hadoop/dfs/specificmount /hadoop/dfs/data
#EXPOSE 9864

# -- Layer: nodemanager

HEALTHCHECK CMD curl -f http://localhost:8042/ || exit 1

#EXPOSE 8042

# -- Layer: resourcemanager

HEALTHCHECK CMD curl -f http://localhost:8088/ || exit 1

#EXPOSE 8088

# -- Layer: historyserver

HEALTHCHECK CMD curl -f http://localhost:8188/ || exit 1

ENV YARN_CONF_yarn_timeline___service_leveldb___timeline___store_path=/hadoop/yarn/timeline
#RUN mkdir -p /hadoop/yarn/timeline
#RUN ln -s /hadoop/dfs/specificmount /hadoop/yarn/timeline
#EXPOSE 8188





VOLUME /hadoop/dfs/specificmount
EXPOSE 9870 9864 8042 8088 8188