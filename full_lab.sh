#!/usr/bin/env bash
set -e

docker compose up -d

until [ "$(docker exec cassandra-1 nodetool status 2>/dev/null | grep -c 'UN ')" -eq 3 ]; do
  sleep 5
done

docker exec -i cassandra-1 cqlsh -e "DROP KEYSPACE IF EXISTS lab4;"
./scripts/1_create_keyspace.sh
./scripts/2_create_table.sh
./scripts/3_seed_leaderboard.sh

docker exec cassandra-1 nodetool getendpoints lab4 leaderboard game_1
docker exec cassandra-1 nodetool getendpoints lab4 leaderboard game_50
docker exec cassandra-1 nodetool getendpoints lab4 leaderboard game_99

docker stop cassandra-2 cassandra-3
sleep 5

docker exec -i cassandra-1 cqlsh -e "CONSISTENCY ONE; SELECT COUNT(*) FROM lab4.leaderboard;"
docker exec -i cassandra-1 cqlsh -e "CONSISTENCY QUORUM; SELECT COUNT(*) FROM lab4.leaderboard;" || true

docker start cassandra-2 cassandra-3
sleep 10

until [ "$(docker exec cassandra-1 nodetool status 2>/dev/null | grep -c 'UN ')" -eq 3 ]; do
  sleep 3
done

./scripts/4_compaction_test_table_creation.sh
./scripts/5_compaction_test_insert.sh

docker exec cassandra-1 nodetool compact lab4 compaction_test

docker exec -i cassandra-1 cqlsh -e "CREATE TABLE IF NOT EXISTS lab4.leaderboard_v1 (game_id text, player_id text, score int, PRIMARY KEY (game_id));"
docker exec -i cassandra-1 cqlsh -e "CREATE TABLE IF NOT EXISTS lab4.leaderboard_v2 (game_id text, player_id text, score int, PRIMARY KEY ((game_id, player_id)));"

for i in $(seq 1 100); do
  docker exec -i cassandra-1 cqlsh -e "INSERT INTO lab4.leaderboard_v1 (game_id, player_id, score) VALUES ('world_cup', 'player_$i', $((RANDOM % 1000)));" 2>/dev/null
done

for i in $(seq 1 100); do
  docker exec -i cassandra-1 cqlsh -e "INSERT INTO lab4.leaderboard_v2 (game_id, player_id, score) VALUES ('world_cup', 'player_$i', $((RANDOM % 1000)));" 2>/dev/null
done

docker exec -i cassandra-1 cqlsh -e "SELECT COUNT(*) FROM lab4.leaderboard_v1 WHERE game_id='world_cup';"
docker exec -i cassandra-1 cqlsh -e "SELECT COUNT(*) FROM lab4.leaderboard_v2 WHERE game_id='world_cup' ALLOW FILTERING;"

echo OK
