# mongo-sharding-repl

То же шардирование, что в `mongo-sharding`, но каждый шард теперь группа репликации из трёх узлов: `shard1-1`, `shard1-2`, `shard1-3` и `shard2-1`, `shard2-2`, `shard2-3`.

## Запуск

```shell
docker compose up -d
```

## Настройка репликации и шардирования

```shell
./scripts/mongo-init.sh
```

Запускать один раз на свежих томах, повторный запуск допишет ещё 1000 документов.

Что делает скрипт:

1. На `configSrv` (порт 27017) инициализирует replica set сервера конфигурации.
2. На `shard1-1` (27018) собирает группу репликации первого шарда:

   ```js
   rs.initiate({_id: "shard1", members: [
     {_id: 0, host: "shard1-1:27018"},
     {_id: 1, host: "shard1-2:27018"},
     {_id: 2, host: "shard1-3:27018"}
   ]})
   ```
3. На `shard2-1` (27019) так же собирает группу `shard2` из `shard2-1`, `shard2-2`, `shard2-3`.
4. Ждёт выбора primary и на `mongos_router` (27020) подключает шарды уже целыми группами, затем шардирует `somedb.helloDoc` по хешу `name`:

   ```js
   sh.addShard("shard1/shard1-1:27018,shard1-2:27018,shard1-3:27018")
   sh.addShard("shard2/shard2-1:27019,shard2-2:27019,shard2-3:27019")
   sh.enableSharding("somedb")
   sh.shardCollection("somedb.helloDoc", {name: "hashed"})
   ```
5. Через роутер записывает 1000 документов.

## Проверка

Приложение: http://localhost:8080. В `collections.helloDoc.documents_count` общее число документов (1000), в `shards` у каждого шарда перечислены все три реплики.

Документы и состояние реплик по шардам:

```shell
./scripts/count-docs.sh
```

Скрипт печатает число документов на шарде и список узлов группы из `rs.status()`. У меня:

```
shard1: 492
  shard1-1:27018 PRIMARY
  shard1-2:27018 SECONDARY
  shard1-3:27018 SECONDARY
shard2: 508
  shard2-1:27019 PRIMARY
  shard2-2:27019 SECONDARY
  shard2-3:27019 SECONDARY
```

Primary выбирается голосованием, поэтому им может оказаться любой из трёх узлов шарда.

## Остановка

```shell
docker compose down -v
```
