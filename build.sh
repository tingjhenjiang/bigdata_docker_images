# -- Software Stack Version

PYTHON_VERSION="3.7" #has to match the system's python version
SPARK_VERSION="3.2.0"
HADOOP_VERSION="3.2"
HADOOP_VERSION_detailed="3.2.2"
SCALA_VERSION="2.13"
SCALA_DETAILED_VERSION="2.13.4"
ALMOND_VERSION="0.11.1"
NB_USERs="user1"
HIVE_VERSION="3.1.2"
POSTGRES_JDBC_DRIVER_VERSION="42.3.1"

# -- Building the Images

docker build \
  --build-arg HADOOP_VERSION="${HADOOP_VERSION_detailed}" \
  -t hadoop-base ./hadoop-ecosystem/hadoop-base

docker build \
  --build-arg SPARK_VERSION="$SPARK_VERSION" \
  --build-arg HADOOP_VERSION="$HADOOP_VERSION" \
  --build-arg SCALA_VERSION="$SCALA_VERSION" \
  -t spark-base ./hadoop-ecosystem/spark

docker build \
  --build-arg SPARK_VERSION="$SPARK_VERSION" \
  --build-arg SCALA_DETAILED_VERSION="$SCALA_DETAILED_VERSION" \
  --build-arg ALMOND_VERSION="$ALMOND_VERSION" \
  -f jupyterhub-run_pyr.Dockerfile -t jupyterhub-run_pyr .

docker build \
  --build-arg HIVE_VERSION="$HIVE_VERSION" \
  --build-arg POSTGRES_JDBC_DRIVER_VERSION="$POSTGRES_JDBC_DRIVER_VERSION" \
  -t hive ./hadoop-ecosystem/hive

docker build -t hive-metastore-postgresql -f ./hadoop-ecosystem/hive/postgres_hive.Dockerfile .

docker compose up -d spark-master spark-worker
docker compose up -d namenode datanode resourcemanager nodemanager historyserver hive-server hive-metastore hive-metastore-postgresql
docker compose up -d hive-server hive-metastore