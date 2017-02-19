#!/usr/bin/env bash
export SPARK_LOCAL_IP=`hostname --ip-address`
cd /usr/local/spark
./bin/spark-shell \
	--master spark://${SPARK_MASTER_PORT_7077_TCP_ADDR}:${SPARK_MASTER_ENV_SPARK_MASTER_PORT}  \
	--conf spark.driver.host=${SPARK_LOCAL_IP} \
	--properties-file /spark-defaults.conf \
	--jars /spark-cassandra-connector-2.0.0-M2-s_2.11.jar \
	--conf spark.cassandra.connection.host=${CASSANDRA_PORT_7001_TCP_ADDR} \
	"$@"
