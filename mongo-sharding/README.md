# mongo-sharding

MongoDB с шардированием: сервер конфигурации `configSrv`, два шарда `shard1` и `shard2`, роутер `mongos_router`. Приложение `pymongo_api` ходит только в роутер.

## Запуск

```shell
docker compose up -d
```

## Инициализация шардирования

```shell
./scripts/mongo-init.sh
```

Запускать один раз на свежих томах, повторный запуск допишет ещё 1000 документов.

Скрипт делает то же, что можно выполнить руками в `mongosh`:

1. На `configSrv` (порт 27017) инициализирует replica set сервера конфигурации:
   `rs.initiate({_id: "config_server", configsvr: true, members: [{_id: 0, host: "configSrv:27017"}]})`
2. На `shard1` (27018) и `shard2` (27019) инициализирует по replica set из одного узла:
   `rs.initiate({_id: "shard1", members: [{_id: 0, host: "shard1:27018"}]})` и так же для `shard2`.
3. На `mongos_router` (27020) подключает шарды, включает шардирование базы `somedb` и коллекции `helloDoc` по хешу поля `name`:

   ```js
   sh.addShard("shard1/shard1:27018")
   sh.addShard("shard2/shard2:27019")
   sh.enableSharding("somedb")
   sh.shardCollection("somedb.helloDoc", {name: "hashed"})
   ```
4. Через роутер записывает в `somedb.helloDoc` 1000 документов.

В конце скрипт печатает общее число документов и число документов на каждом шарде.

## Проверка

Приложение: http://localhost:8080. В ответе `mongo_topology_type: Sharded`, в `collections.helloDoc.documents_count` общее число документов (1000), в `shards` оба шарда.

Сколько документов на каждом шарде:

```shell
./scripts/count-docs.sh
```

У меня получилось 492 на `shard1` и 508 на `shard2`.

## Остановка

```shell
docker compose down -v
```
