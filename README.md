Этап 1. Развертывание
  1. Разверните кластер из 3-х узлов (cassandra-1, cassandra-2, cassandra-3). Выберите RF=3.
  2. Настройте узлы так, чтобы они имитировали разные стойки (rack_1, rack_2, rack_3).
  3. Докажите распределение по стойкам через nodetool status.
  4. Убедитесь, что все узлы в состоянии UN.
Этап 2. Согласованность данных
  1. Создайте таблицу leaderboard (game_id, player_id, score). PK: game_id. CL: QUORUM.
  2. Заполните таблицу данными (добавьте несколько десятков записей). Покажите, сколько ключей хранит каждый узел.
  3. Проведите эксперимент: выключите 2 узла. Попробуйте прочитать данные с CL=ONE. Объясните, почему может быть возвращен некорректный результат в распределенной системе.
  4. Продемонстрируйте работу LOCAL_ONE и объясните отличие от уровня ONE.
Этап 3. Работа с данными
  1. Выполните 100 операций INSERT в одну и ту же запись, изменяя score в каждой записи.
  2. Объясните принцип работы LSM-дерева в Cassandra: почему в файлах данных сейчас 100 записей, а SELECT возвращает только одну?
  3. Запустите принудительное уплотнение (nodetool compact). Покажите, как изменилось количество файлов в директории данных и объем дискового пространства.
Этап 4. Шардирование
  1. Создайте ситуацию, когда все игроки пишут данные в одну игру (game_id = 'world_cup'). Подтвердите, что один узел нагружен сильнее остальных.
  2. Перепроектируйте ключ, сделав player_id частью Partition Key.
  3. Сравните распределение данных между первым и вторым вариантом модели данных.

  
# Выполнение

## Этап 1

первый шаг это поднять три кассандры по условию

  1. Разверните кластер из 3-х узлов (cassandra-1, cassandra-2, cassandra-3). Выберите RF=3.
  2. Настройте узлы так, чтобы они имитировали разные стойки (rack_1, rack_2, rack_3).
  3. Докажите распределение по стойкам через nodetool status.
  4. Убедитесь, что все узлы в состоянии UN.

CASSANDRA_CLUSTER_NAME=MyCluster
CASSANDRA_SEEDS=cassandra-1
CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
CASSANDRA_DC=dc1
CASSANDRA_RACK=rack1

CASSANDRA_RACK - стойки меняются для cassandra-[1,2,3]

так как инстансы зависят друг от друга, мы запускаем их по одному

```bash
❯ ./scripts/check_status.sh
Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack
UN  172.21.0.4  80.05 KiB   16      76.0%             61946db3-d337-431d-bb0b-251ae1c8afaa  rack3
UN  172.21.0.3  80.03 KiB   16      59.3%             add72b86-132c-4229-a959-c0d550201ad9  rack2
UN  172.21.0.2  119.81 KiB  16      64.7%             f3d8bb24-341a-4f44-acd4-8e9ba4356da3  rack1

Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack
UN  172.21.0.4  80.05 KiB   16      76.0%             61946db3-d337-431d-bb0b-251ae1c8afaa  rack3
UN  172.21.0.3  80.03 KiB   16      59.3%             add72b86-132c-4229-a959-c0d550201ad9  rack2
UN  172.21.0.2  119.81 KiB  16      64.7%             f3d8bb24-341a-4f44-acd4-8e9ba4356da3  rack1

Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack
UN  172.21.0.4  80.05 KiB   16      76.0%             61946db3-d337-431d-bb0b-251ae1c8afaa  rack3
UN  172.21.0.3  80.03 KiB   16      59.3%             add72b86-132c-4229-a959-c0d550201ad9  rack2
UN  172.21.0.2  119.81 KiB  16      64.7%             f3d8bb24-341a-4f44-acd4-8e9ba4356da3  rack1
```

## Этап 2

### 2.1 

Создаем KEYSPACE (аналог DATABASE в PG)

```bash
❯ docker exec -i cassandra-1 cqlsh -e "
CREATE KEYSPACE lab4 WITH replication = {
  'class': 'NetworkTopologyStrategy',
  'dc1': 3
};"
```

Создаем таблицу

```bash
docker exec -i cassandra-1 cqlsh -e "
CREATE TABLE lab4.leaderboard (
  game_id text,
  player_id text,
  score int,
  PRIMARY KEY (game_id)
);"
```
`game_id` - partition key. Все строки с одинаковым `game_id` будут храниться на одном узле (реплицируемом)

### 2.2

засидим бд
```bash
❯ ./scripts/3_seed_leaderboard.sh
Consistency level set to QUORUM.

Warnings :
Batch for [lab4.leaderboard] is of size 10292, exceeding specified threshold of 5120 by 5172.


 count
-------
   100

(1 rows)

Warnings :
Aggregation query used without partition key
```

```bash
~/dev/distributed-databases/distributed-databases-lab4 main* ⇡
❯ ./scripts/check_status.sh
Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack
UN  172.21.0.4  152.68 KiB  16      100.0%            61946db3-d337-431d-bb0b-251ae1c8afaa  rack3
UN  172.21.0.3  152.66 KiB  16      100.0%            add72b86-132c-4229-a959-c0d550201ad9  rack2
UN  172.21.0.2  195.73 KiB  16      100.0%            f3d8bb24-341a-4f44-acd4-8e9ba4356da3  rack1
```

### 2.3

чтение:

```bash
~/dev/distributed-databases/distributed-databases-lab4 main* ⇡
❯ docker exec -it cassandra-1 cqlsh -e 'select * from lab4.leaderboard;'

 game_id  | player_id  | score
----------+------------+-------
  game_34 |  player_34 |   795
  game_58 |  player_58 |   536
  game_71 |  player_71 |   373
  game_42 |  player_42 |   277
  game_47 |  player_47 |   312
  game_87 |  player_87 |   425
  game_38 |  player_38 |   793
  game_19 |  player_19 |   854
  game_82 |  player_82 |   759
  game_50 |  player_50 |   558
  game_33 |  player_33 |   691
  game_68 |  player_68 |   811
  game_98 |  player_98 |   570
  game_59 |  player_59 |   193
  game_77 |  player_77 |   960
  game_12 |  player_12 |   108
   game_4 |   player_4 |   611
   game_2 |   player_2 |    44
  game_63 |  player_63 |   182
  game_28 |  player_28 |   586
  game_35 |  player_35 |   259
  game_56 |  player_56 |   671
  game_27 |  player_27 |   571
  game_10 |  player_10 |   661
   game_9 |   player_9 |   628
  game_96 |  player_96 |   748
  game_86 |  player_86 |   686
  game_66 |  player_66 |   318
  game_85 |  player_85 |    25
   game_7 |   player_7 |   242
  game_26 |  player_26 |   570
  game_84 |  player_84 |   546
  game_69 |  player_69 |   704
  game_76 |  player_76 |   181
  game_39 |  player_39 |    36
  game_43 |  player_43 |   869
  game_49 |  player_49 |   141
  game_25 |  player_25 |   911
  game_72 |  player_72 |     4
  game_55 |  player_55 |   150
  game_52 |  player_52 |   253
  game_94 |  player_94 |   876
  game_48 |  player_48 |     4
  game_30 |  player_30 |   641
  game_95 |  player_95 |    26
  game_78 |  player_78 |   321
  game_22 |  player_22 |   593
  game_97 |  player_97 |   921
  game_18 |  player_18 |   754
  game_14 |  player_14 |   361
  game_31 |  player_31 |   714
  game_45 |  player_45 |   298
  game_62 |  player_62 |   829
  game_73 |  player_73 |   298
  game_29 |  player_29 |   541
  game_36 |  player_36 |   400
  game_60 |  player_60 |   363
  game_91 |  player_91 |   727
  game_67 |  player_67 |   934
  game_13 |  player_13 |   506
   game_1 |   player_1 |   333
   game_3 |   player_3 |   567
  game_46 |  player_46 |   815
  game_20 |  player_20 |   766
  game_44 |  player_44 |   478
  game_11 |  player_11 |   643
  game_57 |  player_57 |   218
  game_15 |  player_15 |   312
  game_40 |  player_40 |   391
  game_81 |  player_81 |   385
  game_61 |  player_61 |   485
  game_79 |  player_79 |   568
  game_99 |  player_99 |   321
  game_41 |  player_41 |   352
  game_37 |  player_37 |   466
  game_54 |  player_54 |   261
  game_21 |  player_21 |   696
   game_5 |   player_5 |   906
  game_83 |  player_83 |   924
  game_89 |  player_89 |   390
  game_92 |  player_92 |   184
  game_70 |  player_70 |   766
  game_32 |  player_32 |   987
  game_90 |  player_90 |   989
  game_80 |  player_80 |   245
   game_6 |   player_6 |   415
  game_24 |  player_24 |    66
  game_51 |  player_51 |   155
  game_75 |  player_75 |    52
  game_74 |  player_74 |   889
  game_65 |  player_65 |   166
  game_93 |  player_93 |   351
  game_88 |  player_88 |   862
   game_8 |   player_8 |   380
  game_16 |  player_16 |   685
  game_23 |  player_23 |     8
  game_53 |  player_53 |   266
  game_64 |  player_64 |   120
  game_17 |  player_17 |   170
 game_100 | player_100 |   971

(100 rows)
```

остановка:
```bash
docker stop cassandra-2 cassandra-3
```

```bash
❯ docker exec -it cassandra-1 cqlsh -e 'CONSISTENCY QUORUM; select * from lab4.leaderboard;'
Consistency level set to QUORUM.
<stdin>:1:NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 dc1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level QUORUM" info={\'consistency\': \'QUORUM\', \'required_replicas\': 2, \'alive_replicas\': 1}')})
```

CL=QUORUM:
- отвечает после подтверждения от `RF/2 + 1 = 2` узлов
- при одном живом узле QUORUM недостижим → ошибка `UnavailableException`

Cassandra использует **eventual consistency** — данные асинхронно реплицируются между узлами. Если запись пришла с CL=ONE, только один узел её получил. Чтение с CL=ONE с другого узла может не увидеть эту запись. Это классическая проблема распределённых систем — компромисс между доступностью и консистентностью (CAP-теорема).

CAP:
- Consistency
- Availability
- Partition tolerance
- CL=ONE - AP
- CL=QUORUM - CP

### 2.4

В одно-дата-центровом кластере `LOCAL_ONE` и `ONE` работают одинаково, в multi-DC конфигурациях:
- `ONE` - может прочитать с любого узла в любом дата-центре
- `LOCAL_ONE` - читает только с узла в локальном дата-центре

## Этап 3

### 3.1

создадим таблицу 
```cql
CREATE TABLE lab4.compaction_test (
  game_id text,
  player_id text,
  score int,
  PRIMARY KEY (game_id)
);
ALTER TABLE lab4.compaction_test WITH compaction = {
  'class': 'SizeTieredCompactionStrategy',
  'min_threshold': 10000,
  'max_threshold': 10000
};
```
min_threshold = 10000, он точно не сразу сработает

### 3.2

потом вызываем запись и флашим на диск изменения

```bash
docker exec -i cassandra-1 bash << 'SCRIPT'
for i in $(seq 1 100); do
  cqlsh -e "INSERT INTO lab4.compaction_test (game_id, player_id, score) VALUES ('game_triple_t', 'player_$i', $i);"
  nodetool flush lab4 compaction_test
  echo "$i/100"
done
SCRIPT
```

теперь смотрим сколько создалось файлов:

```bash
docker exec cassandra-1 bash -c 'ls /var/lib/cassandra/data/lab4/compaction_test-*/*-Data.db | wc -l'
230
```

хотя у нас всего одна строка:

```bash
~/dev/distributed-databases/distributed-databases-lab4 main* 2m 22s
❯ docker exec -it cassandra-1 cqlsh -e 'select * from lab4.compaction_test;'

 game_id       | player_id  | score
---------------+------------+-------
 game_triple_t | player_100 |   100

(1 rows)
```

### 3.3

теперь делаем compaction:

```bash
❯ docker exec cassandra-1 bash -c 'nodetool compact lab4 compaction_test'

❯ docker exec cassandra-1 bash -c 'ls /var/lib/cassandra/data/lab4/compaction_test-*/*-Data.db | wc -l'
1
```

данные не изменились:

```bash
❯ docker exec -it cassandra-1 cqlsh -e 'select * from lab4.compaction_test;'

 game_id       | player_id  | score
---------------+------------+-------
 game_triple_t | player_100 |   100

(1 rows)
```

## Этап 4

### 4.1

запуская ./scripts/stress_test_hot_spot.sh

```bash
#!/usr/bin/env bash

for i in $(seq 1 100); do
  docker exec -i cassandra-1 cqlsh \
    -e "INSERT INTO lab4.leaderboard (game_id, player_id, score)
        VALUES ('world_cup', 'player_$i', $((RANDOM % 1000)));" &
done
```

можно в lazydocker увидеть

| Status | Name | CPU |
|--------|------|-----|
| running (healthy) | cassandra-1 | 71.54% |
| running (healthy) | cassandra-2 | 0.46% |
| running (healthy) | cassandra-3 | 0.42% |

слишком большая нагрузка на первый узел

### 4.2


создадим таблицу с композитным PK

```bash
docker exec -i cassandra-1 cqlsh -e "
CREATE TABLE lab4.leaderboard_v2 (
  game_id text,
  player_id text,
  score int,
  PRIMARY KEY ((game_id, player_id))
);"

```

hash('world_cup') vs hash('world_cup:player_1')

### 4.3

в первой версии:
```bash
❯ ./scripts/stress_test_hot_spot_v1.sh
172.21.0.3
```
совпадает с примари реплика

во второй версии
```bash
❯ ./scripts/stress_test_hot_spot_v2.sh
172.21.0.4
172.21.0.3
172.21.0.3
172.21.0.4
172.21.0.2
```
рандом
