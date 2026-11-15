#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# mongod принимает соединения не сразу после старта контейнера
wait_mongo() {
  until docker compose exec -T "$1" mongosh --port "$2" --quiet --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
    sleep 1
  done
}

wait_primary() {
  until docker compose exec -T "$1" mongosh --port "$2" --quiet --eval "rs.status().members.some(m => m.state == 1)" 2>/dev/null | grep -q true; do
    sleep 1
  done
}

echo "Сервер конфигурации"
wait_mongo configSrv 27017
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF_JS
rs.initiate({_id: "config_server", configsvr: true, members: [{_id: 0, host: "configSrv:27017"}]})
EOF_JS

echo "Группа репликации shard1"
for n in shard1-1 shard1-2 shard1-3; do wait_mongo $n 27018; done
docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF_JS
rs.initiate({_id: "shard1", members: [
  {_id: 0, host: "shard1-1:27018"},
  {_id: 1, host: "shard1-2:27018"},
  {_id: 2, host: "shard1-3:27018"}
]})
EOF_JS

echo "Группа репликации shard2"
for n in shard2-1 shard2-2 shard2-3; do wait_mongo $n 27019; done
docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF_JS
rs.initiate({_id: "shard2", members: [
  {_id: 0, host: "shard2-1:27019"},
  {_id: 1, host: "shard2-2:27019"},
  {_id: 2, host: "shard2-3:27019"}
]})
EOF_JS

# addShard упадёт, если в шарде ещё не выбран primary
wait_primary configSrv 27017
wait_primary shard1-1 27018
wait_primary shard2-1 27019
wait_mongo mongos_router 27020

echo "Роутер: подключаем шарды, шардируем somedb.helloDoc и наполняем"
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF_JS
sh.addShard("shard1/shard1-1:27018,shard1-2:27018,shard1-3:27018")
sh.addShard("shard2/shard2-1:27019,shard2-2:27019,shard2-3:27019")
sh.enableSharding("somedb")
sh.shardCollection("somedb.helloDoc", {name: "hashed"})
use somedb
for (var i = 0; i < 1000; i++) db.helloDoc.insertOne({age: i, name: "ly" + i})
print("всего документов: " + db.helloDoc.countDocuments())
EOF_JS

./scripts/count-docs.sh
