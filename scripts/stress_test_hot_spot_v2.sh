#!/usr/bin/env bash
set -e

NODES=(cassandra-1 cassandra-2 cassandra-3)

for i in $(seq 1 100); do
  node=${NODES[$((i % 3))]}
  docker exec -i "$node" cqlsh \
    -e "INSERT INTO lab4.leaderboard_v2 (game_id, player_id, score)
        VALUES ('world_cup', 'player_$i', $((RANDOM % 1000)));" &
done
wait

for i in 1 25 50 75 100; do
  docker exec -i cassandra-1 nodetool getendpoints lab4 leaderboard_v2 "world_cup:player_$i" 2>/dev/null | head -1
done
