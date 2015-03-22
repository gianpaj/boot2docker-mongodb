# boot2docker-mongodb

Bash script to start a MongoDB sharded cluster using docker on OS X (via boot2docker). It uses IP addresses for container communication.

Inspired by Alex Komyagin's [mongo-docker](https://github.com/adkomyagin/mongo-docker).

Using official [docker image](https://registry.hub.docker.com/_/mongo/).

Current setup:

- 2 replica sets (3 data notes)
- 3 config servers
- 1 mongos node

Get started:

```bash
git clone git@github.com:gianpaj/boot2docker-mongodb.git
cd boot2docker-mongodb
source setup.sh
```

Example output:

	Writing /Users/gianfranco/.boot2docker/certs/boot2docker-vm/ca.pem
	Writing /Users/gianfranco/.boot2docker/certs/boot2docker-vm/cert.pem
	Writing /Users/gianfranco/.boot2docker/certs/boot2docker-vm/key.pem
	Creating mongo_rs1_1...
	Creating mongo_rs1_2...
	Creating mongo_rs1_3...
	Starting mongo_rs1_1...
	Starting mongo_rs1_2...
	Starting mongo_rs1_3...
	Creating mongo_rs2_1...
	Creating mongo_rs2_2...
	Creating mongo_rs2_3...
	Starting mongo_rs2_1...
	Starting mongo_rs2_2...
	Starting mongo_rs2_3...
	Initiating replica set
	{ "ok" : 1 }
	Initiating replica set
	{ "ok" : 1 }
	Creating mongo_cfg_1...
	Creating mongo_cfg_2...
	Creating mongo_cfg_3...
	Starting mongo_cfg_1...
	Starting mongo_cfg_2...
	Starting mongo_cfg_3...
	Starting mongos...
	075e82eff8743d15e46cbf9fc040c4b3bd704ab0b9f74b9c073716313f9800da
	{ "shardAdded" : "rs1", "ok" : 1 }
	{ "shardAdded" : "rs2", "ok" : 1 }
	{ "nInserted" : 1 }
	{
		"raw" : {
			"rs2/172.17.0.57:27017,172.17.0.58:27017,172.17.0.59:27017" : {
				"createdCollectionAutomatically" : false,
				"numIndexesBefore" : 1,
				"numIndexesAfter" : 2,
				"ok" : 1,
				"$gleStats" : {
					"lastOpTime" : Timestamp(1427043270, 3),
					"electionId" : ObjectId("550ef3b7702605233a3b52af")
				}
			}
		},
		"ok" : 1
	}
	{ "ok" : 1 }
	{ "collectionsharded" : "test.test", "ok" : 1 }
	#####################################
	MongoDB Cluster is now ready to use
	Connect to cluster:
	$ docker exec -it mongos mongo
	
Connect to sharded cluster:

	$ docker exec -it mongos mongo
	MongoDB shell version: 3.0.0
	connecting to: test
	Welcome to the MongoDB shell.
	For interactive help, type "help".
	For more comprehensive documentation, see
		http://docs.mongodb.org/
	Questions? Try the support group
		http://groups.google.com/group/mongodb-user
	Server has startup warnings:
	2015-03-22T16:54:19.591+0000 I CONTROL  ** WARNING: You are running this process as the root user, which is not recommended.
	2015-03-22T16:54:19.592+0000 I CONTROL
	mongos> sh.status()
	--- Sharding Status ---
	  sharding version: {
		"_id" : 1,
		"minCompatibleVersion" : 5,
		"currentVersion" : 6,
		"clusterId" : ObjectId("550ef3bc06152859f0406435")
	}
	  shards:
		{  "_id" : "rs1",  "host" : "rs1/172.17.0.54:27017,172.17.0.55:27017,172.17.0.56:27017" }
		{  "_id" : "rs2",  "host" : "rs2/172.17.0.57:27017,172.17.0.58:27017,172.17.0.59:27017" }
	  balancer:
		Currently enabled:  yes
		Currently running:  no
		Failed balancer rounds in last 5 attempts:  0
		Migration Results for the last 24 hours:
			No recent migrations
	  databases:
		{  "_id" : "admin",  "partitioned" : false,  "primary" : "config" }
		{  "_id" : "test",  "partitioned" : true,  "primary" : "rs2" }
			test.test
				shard key: { "_id" : "hashed" }
				chunks:
					rs2	1
				{ "_id" : { "$minKey" : 1 } } -->> { "_id" : { "$maxKey" : 1 } } on : rs2 Timestamp(1, 0)
