# How to setup a cluster with Spark 2.1 + Cassandra 3.6 using Docker 1.13 ?

Spark is hype, Cassandra is cool and docker is awesome. Let's have some "fun" with all of this to be able to try machine learning without the pain to install C* and Spark on your computer.

Thanks to this official docker image of C*, running a Cassandra cluster is really straighforward: https://registry.hub.docker.com/_/cassandra/

I just used those repositories and add the fat jar assembly of spark-cassandra-connector into the image + some configuration to have a cluster with:
* 1 Spark master
* N Cassandra + Spark workers
* 1 cqlsh console (optional)
* 1 Spark shell (optional)

Let's Go!

## Install docker and git


## Build Docker image
docker build --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy -t sparkassandra-dockerized .

## Run your own Spark 2.1 + Cassandra 3.6 cluster using Docker!

```
# run a Spark master
docker run -d -t -P --name spark_master sparkassandra-dockerized /start-master.sh

# run a Cassandra + Spark worker node
docker run -it --name some-cassandra --link spark_master:spark_master -d sparkassandra-dockerized

# (optional) run some other nodes if you wish
docker run -it --link spark_master:spark_master --link some-cassandra:cassandra -d sparkassandra-dockerized
```

Here you have a Cassandra + Spark cluster running without installing anything but Docker. #cool

## Try your Cassandra cluster

To test your Cassandra cluster, you can run a cqlsh console to insert some data:

```
# run a Cassandra cqlsh console
docker run -it --link some-cassandra:cassandra --rm sparkassandra-dockerized cqlsh cassandra

# create some data and retrieve them:
cqlsh>CREATE KEYSPACE test WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1 };

cqlsh>CREATE TABLE test.kv(key text PRIMARY KEY, value int);

cqlsh>INSERT INTO test.kv(key, value) VALUES ('key1', 1);

cqlsh>INSERT INTO test.kv(key, value) VALUES ('key2', 2);

cqlsh>SELECT * FROM test.kv;

 key  | value
------+-------
 key1 |     1
 key2 |     2

(2 rows)
```

## Try your Spark cluster

To test your Spark cluster, you can run a shell to read/write data from/to Cassandra:

```
# run a Spark shell
docker run -i -t -P --link spark_master:spark_master --link some-cassandra:cassandra sparkassandra-dockerized /spark-shell.sh

# check you can retrieve your Cassandra data using Spark
scala>import com.datastax.spark.connector._
...
scala>val rdd = sc.cassandraTable("test", "kv")
rdd: com.datastax.spark.connector.rdd.CassandraTableScanRDD[com.datastax.spark.connector.CassandraRow] = CassandraTableScanRDD[0] at RDD at CassandraRDD.scala:15

scala>println(rdd.count)
2

scala>println(rdd.first)
CassandraRow{key: key1, value: 1}

scala>println(rdd.map(_.getInt("value")).sum)
3.0

scala>val collection = sc.parallelize(Seq(("key3", 3), ("key4", 4)))
collection: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[4] at parallelize at <console>:24

scala>collection.saveToCassandra("test", "kv", SomeColumns("key", "value"))
...

scala>println(rdd.map(_.getInt("value")).sum)
10.0
```

Et voila !

## Working with Docker composer

Default configuration:
* 1 Spark master
* 1 Cassandra + Spark worker
* N Pool (Cassandra + Spark worker)
* 1 S3 service

Exposed interfaces:
* Spark master WebUI port http://127.0.0.1:8080
* S3 Browser Access  http://127.0.0.1:9000
* CQL on first Cassandra instance
* Spark master job submission port

```
# start Saprk sluster
docker-compose up -d
```

```
# scale Workers pool
docker-compose scale worker=6
```

```
# stop and remove cluster
docker-compose scale worker=0
docker-compose stop
docker-compose rm
```

Connect to Cassandra with:
```
~/.ccm/repository/3.6/bin/cqlsh
```
Connect to Spark Master with:
```
/usr/lib/spark/bin/spark-shell --master spark://localhost:7077 --jars scripts/spark-cassandra-connector-2.0.0-M2-s_2.11.jar --conf spark.cassandra.connection.host=localhost
```


## THE END of the boring installation part, now eat and digest data to extract value!
