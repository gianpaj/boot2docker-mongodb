#!/bin/bash

$(boot2docker shellinit)

# export DOCKERIP="192.168.59.103"

# mongodb container tag (ie. latest)
mongo_version=latest

# Clean up
containers=( mongo_rs1_1 mongo_rs1_2 mongo_rs1_3 mongo_rs2_1 mongo_rs2_2 mongo_rs2_3 mongo_cfg_1 mongo_cfg_2 mongo_cfg_3 mongos )
for c in ${containers[@]}; do
	docker rm -f ${c} > /dev/null 2>&1
done

# start 2 replica sets with 3 nodes each
docker-compose -p mongo scale rs1=3
docker-compose -p mongo scale rs2=3

# (equivalet to)
# docker run --name rs1_srv1 -P -d mongo mongod --noprealloc --smallfiles --replSet rs1

# get IPs of replica set containers (TODO run in loop. like ^ containers)
RS1_1=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" mongo_rs1_1)
RS1_2=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" mongo_rs1_2)
RS1_3=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" mongo_rs1_3)

RS2_1=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" mongo_rs2_1)
RS2_2=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" mongo_rs2_2)
RS2_3=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" mongo_rs2_3)

echo "Initiating replica set"
docker exec -it mongo_rs1_1 mongo --quiet --eval "printjson(rs.initiate({ _id : 'rs1', members : [ {_id : 0, host : '$RS1_1:27017'}, {_id : 1, host : '$RS1_2:27017'}, {_id : 2, host : '$RS1_3:27017'} ] }))"

# wait for replica set to be initiated
sleep 5

echo "Initiating replica set"
docker exec -it mongo_rs2_1 mongo --quiet --eval "printjson(rs.initiate({ _id : 'rs2', members : [ {_id : 0, host : '$RS2_1:27017'}, {_id : 1, host : '$RS2_2:27017'}, {_id : 2, host : '$RS2_3:27017'} ] }))"

# wait for replica set to be initiated
sleep 5

# start 3 config servers
docker-compose -p mongo scale cfg=3

# get IPs of config containers
CFG1=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" mongo_cfg_1)
CFG2=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" mongo_cfg_2)
CFG3=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" mongo_cfg_3)

# start a mongos node
echo "Starting mongos..."
# docker run --name mongos -P -d mongo:$mongo_version mongos --configdb "$CFG1":27017,"$CFG2":27017,"$CFG3":27017 > /dev/null 2>&1
docker run --name mongos -P -d mongo:"$mongo_version" mongos --configdb "$CFG1":27017,"$CFG2":27017,"$CFG3":27017 --setParameter userCacheInvalidationIntervalSecs=30

# Wait for mongos node to start
sleep 5

read -r -d '' ADDSHARDS <<- EOM
	printjson( sh.addShard('rs1/$RS1_1:27017,$RS1_2:27017,$RS1_3:27017') );
	printjson( sh.addShard('rs2/$RS2_1:27017,$RS2_2:27017,$RS2_3:27017') );
EOM

# echo $ADDSHARDS

docker exec -it mongos mongo --quiet --eval "$ADDSHARDS"

# Wait for addShards to be completed
sleep 5

read -r -d '' ENABLESHARDING <<- EOM
	printjson( db.test.insert({a:1}) );
	printjson( db.test.ensureIndex( { _id:"hashed" } ) );
	printjson( db.adminCommand( { enableSharding : "test" } ) );
	printjson( sh.shardCollection( "test.test", { _id: "hashed" } ) );
EOM

docker exec -it mongos mongo --quiet --eval "$ENABLESHARDING"

# Wait for sharding to be enabled
sleep 5

# increase log level
# docker exec -it mongos mongo --quiet --eval "printjson( db.adminCommand( { setParameter: 1, logLevel: 2 } ) );"

echo "#####################################"
echo "MongoDB Cluster is now ready to use"
echo "Connect to cluster:"
echo "$ docker exec -it mongos mongo"

# --------------

# install iptables on 3rd config srv
# docker exec -it mongo_cfg_3 bash
# $ apt-get update -qq && apt-get install -yqq iptables

# block connections
# $ iptables -A INPUT -j DROP
# $ iptables -A OUTPUT -j DROP

# unblock connections
# $ iptables -F

# grep config srv logs (this can slow down operations)
# docker logs -f mongos | grep $(docker inspect -f "{{ .NetworkSettings.IPAddress }}" mongo_cfg_3)