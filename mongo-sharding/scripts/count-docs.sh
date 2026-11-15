#!/bin/bash
# сколько документов helloDoc лежит на каждом шарде
cd "$(dirname "$0")/.."

docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF_JS
use somedb
print("shard1: " + db.helloDoc.countDocuments())
EOF_JS

docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF_JS
use somedb
print("shard2: " + db.helloDoc.countDocuments())
EOF_JS
