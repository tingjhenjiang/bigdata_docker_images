FROM cluster-base

# -- Layer: kafka-base
ARG KAFKA_VERSION=3.0.0
ARG SCALA_VERSION=2.13

RUN apt update && \
    apt install wget git && \
    wget https://www.apache.org/dyn/closer.cgi?path=/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    git clone https://github.com/obsidiandynamics/kafdrop.git --depth=1 && \
    apt-get clean && \
    apt-get autoclean && \
    rm -Rf /tmp/*

# -- Runtime

EXPOSE 9092
EXPOSE 6667
EXPOSE 2183
WORKDIR ${SHARED_WORKSPACE}
ENV FINAL_RUN_INIT_SCRIPT=$FINAL_RUN_INIT_SCRIPT
CMD ["sh","-c","${FINAL_RUN_INIT_SCRIPT}"]