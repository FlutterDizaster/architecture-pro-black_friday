#!/bin/bash
# сколько документов helloDoc лежит на каждом шарде и какие у шарда реплики
cd "$(dirname "$0")/.."

docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF_JS
use somedb
print("shard1: " + db.helloDoc.countDocuments())
rs.status().members.forEach(m => print("  " + m.name + " " + m.stateStr))
EOF_JS

docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF_JS
use somedb
print("shard2: " + db.helloDoc.countDocuments())
rs.status().members.forEach(m => print("  " + m.name + " " + m.stateStr))
EOF_JS
