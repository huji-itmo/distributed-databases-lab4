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
