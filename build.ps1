# -- Software Stack Version

$PYTHON_VERSION="3.9" #has to match the system's python version
$SPARK_VERSION="3.2.0"
$HADOOP_VERSION="3.2"
$HADOOP_VERSION_detailed="3.2.2"
$SCALA_VERSION="2.13"
$SCALA_DETAILED_VERSION="2.13.4"
$ALMOND_VERSION="0.11.1"
$NB_USERs="user1"
$HIVE_VERSION="3.1.2"
$POSTGRES_JDBC_DRIVER_VERSION="42.3.1"

# -- Building the Images

Invoke-Expression -Command ("docker build --build-arg HADOOP_VERSION=" + $HADOOP_VERSION_detailed + " -t hadoop-base ./hadoop-ecosystem/hadoop-base")
#9870 namenode
#9864 datanode
#8188 historyserver
#8042 nodemanager
#8088 resourcemanager
Invoke-Expression -Command ("docker build --build-arg SPARK_VERSION=" + $SPARK_VERSION + " --build-arg HADOOP_VERSION=" + $HADOOP_VERSION + " --build-arg SCALA_VERSION=" + $SCALA_VERSION+ " -t spark-base ./hadoop-ecosystem/spark")
Invoke-Expression -Command ("docker build --build-arg SPARK_VERSION=" + $SPARK_VERSION + " --build-arg SCALA_DETAILED_VERSION=" + $SCALA_DETAILED_VERSION + " --build-arg ALMOND_VERSION="+ $ALMOND_VERSION + " -f jupyterhub-run_pyr.Dockerfile -t jupyterhub-run_pyr .")
Invoke-Expression -Command ("docker build --build-arg SPARK_VERSION=" + $SPARK_VERSION + " --build-arg SCALA_DETAILED_VERSION=" + $SCALA_DETAILED_VERSION + " --build-arg ALMOND_VERSION="+ $ALMOND_VERSION + " --build-arg PYTHON_VERSION="+ $PYTHON_VERSION +" -f jupyterhub-cuda-run_pyr.Dockerfile -t jupyterhub-cuda-run_pyr .")

# -- Building the Images


#Invoke-Expression -Command ("docker build -t tomcat ./hadoop-ecosystem/tomcat")
Invoke-Expression -Command ("docker build --build-arg HIVE_VERSION=" + $HIVE_VERSION + "  --build-arg POSTGRES_JDBC_DRIVER_VERSION=" + $POSTGRES_JDBC_DRIVER_VERSION + " -t hive ./hadoop-ecosystem/hive")
Invoke-Expression -Command ("docker build -t hive-metastore-postgresql -f ./hadoop-ecosystem/hive/postgres_hive.Dockerfile .")


docker compose up -d jupyterhub
docker compose up -d spark-master spark-worker
docker compose up -d namenode datanode resourcemanager nodemanager historyserver hive-server hive-metastore hive-metastore-postgresql
docker compose up -d hive-server hive-metastore