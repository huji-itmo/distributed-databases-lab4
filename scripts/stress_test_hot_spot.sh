#!/usr/bin/env bash

for i in $(seq 1 100); do
  docker exec -i cassandra-1 cqlsh \
    -e "INSERT INTO lab4.leaderboard (game_id, player_id, score)
        VALUES ('world_cup', 'player_$i', $((RANDOM % 1000)));" &
done
