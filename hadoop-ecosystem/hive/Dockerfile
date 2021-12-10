FROM hadoop-base

MAINTAINER Yiannis Mouchakis <gmouchakis@iit.demokritos.gr>
MAINTAINER Ivan Ermilov <ivan.s.ermilov@gmail.com>

# Allow buildtime config of HIVE_VERSION
ARG HIVE_VERSION=3.1.2
ARG POSTGRES_JDBC_DRIVER_VERSION=42.3.1
#9.4.1212
# Set HIVE_VERSION from arg if provided at build, env if provided at run, or default
# https://docs.docker.com/engine/reference/builder/#using-arg-variables
# https://docs.docker.com/engine/reference/builder/#environment-replacement
#ENV HIVE_VERSION=${HIVE_VERSION:-2.3.2}
ENV POSTGRES_JDBC_DRIVER_VERSION=${POSTGRES_JDBC_DRIVER_VERSION}
ENV HIVE_VERSION=${HIVE_VERSION}

ENV HIVE_HOME=/opt/hive
ENV PATH=$HIVE_HOME/bin:$PATH
#ENV HADOOP_HOME /opt/hadoop-$HADOOP_VERSION

WORKDIR /opt

#Install Hive and PostgreSQL JDBC
RUN apt-get update && apt-get install -y wget procps && \
	wget https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz && \
	tar -xzvf apache-hive-$HIVE_VERSION-bin.tar.gz && \
	mv apache-hive-$HIVE_VERSION-bin hive && \
	rm $HIVE_HOME/lib/postgresql-*.jre7.jar && \
	wget https://jdbc.postgresql.org/download/postgresql-$POSTGRES_JDBC_DRIVER_VERSION.jar -P $HIVE_HOME/lib && \
	rm apache-hive-$HIVE_VERSION-bin.tar.gz


#apt install software-properties-common
#wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -
#add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
#apt update && apt install adoptopenjdk-8-hotspot -y
#update-alternatives --set java /usr/lib/jvm/adoptopenjdk-8-hotspot-amd64/bin/java
#cat /etc/*-release

#Spark should be compiled with Hive to be able to use it
#hive-site.xml should be copied to $SPARK_HOME/conf folder

#Custom configuration goes here
ADD conf/hive-site.xml $HIVE_HOME/conf
ADD conf/beeline-log4j2.properties $HIVE_HOME/conf
ADD conf/hive-env.sh $HIVE_HOME/conf
ADD conf/hive-exec-log4j2.properties $HIVE_HOME/conf
ADD conf/hive-log4j2.properties $HIVE_HOME/conf
ADD conf/ivysettings.xml $HIVE_HOME/conf
ADD conf/llap-daemon-log4j2.properties $HIVE_HOME/conf
RUN find $HIVE_HOME/conf -type f -print0 | xargs -0 -n 1 -P 4 dos2unix

COPY startup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/startup.sh && \
	dos2unix /usr/local/bin/startup.sh

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh && \
	dos2unix /usr/local/bin/entrypoint.sh

#prevent different guava version conflict
RUN rm $HIVE_HOME/lib/guava*.jar && \
	cp $HADOOP_HOME/share/hadoop/common/lib/guava-27.0-jre.jar $HIVE_HOME/lib

RUN echo '#!/bin/bash \
		  \n$HIVE_HOME/bin/schematool -ifNotExists -dbType postgres -initSchema \
          \n/opt/hive/bin/hive --service metastore --hiveconf hive.root.logger=INFO,console' \
          > /usr/local/bin/init_metastore.sh && \
	chmod +x /usr/local/bin/init_metastore.sh

#RUN wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.0.12/bin/apache-tomcat-10.0.12.tar.gz -P / && \
#	tar zxvf apache-tomcat-10.0.12.tar.gz && \
#    rm /apache-tomcat-10.0.12.tar.gz && \
#	mv /apache-tomcat-10.0.12 /usr/local/bin/tomcat

RUN apt-get --purge remove -y dos2unix wget && \
	apt-get clean && \
	apt-get autoclean && \
	rm -rf /var/lib/apt/lists/*

EXPOSE 10000
EXPOSE 10002

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD /usr/local/bin/startup.sh
#CMD ["/usr/local/bin/tomcat/bin/catalina.sh", "run"]
