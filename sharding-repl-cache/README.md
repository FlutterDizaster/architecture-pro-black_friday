# sharding-repl-cache

Итоговый стенд: шардирование (два шарда), репликация (по три узла в каждом шарде) и кеш в Redis. От `mongo-sharding-repl` отличается сервисом `redis` и переменной `REDIS_URL` у приложения.

## Запуск

```shell
docker compose up -d
./scripts/mongo-init.sh
```

Скрипт запускается один раз на свежих томах.

Скрипт настраивает сервер конфигурации, собирает группы репликации `shard1` и `shard2`, подключает их к роутеру, шардирует `somedb.helloDoc` по хешу `name` и записывает 1000 документов. Подробно по шагам команды расписаны в `mongo-sharding-repl/README.md`, здесь они те же. Redis настраивать не нужно: приложению хватает `REDIS_URL: "redis://redis:6379"`.

## Проверка

Приложение: http://localhost:8080. В ответе `documents_count` 1000, в `shards` по три реплики на шард, `cache_enabled: true`.

Документы и реплики по шардам:

```shell
./scripts/count-docs.sh
```

Кеш работает на эндпоинте `/helloDoc/users`. Первый запрос идёт в MongoDB, следующие минуту берутся из Redis:

```shell
for i in 1 2 3; do curl -o /dev/null -s -w "%{time_total}s\n" http://localhost:8080/helloDoc/users; done
```

У меня получилось 1.06 с на первом запросе и 0.009 с, 0.007 с на повторных.

## Остановка

```shell
docker compose down -v
```
