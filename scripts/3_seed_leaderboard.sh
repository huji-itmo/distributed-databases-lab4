#!/usr/bin/env bash
set -e

BATCH=""
for i in $(seq 1 100); do
  score=$((RANDOM % 1000))
  BATCH+=" INSERT INTO lab4.leaderboard (game_id, player_id, score) VALUES ('game_$i', 'player_$i', $score);"
done

docker exec -i cassandra-1 cqlsh -e "CONSISTENCY QUORUM; $BATCH"
docker exec -i cassandra-1 cqlsh -e "SELECT COUNT(*) FROM lab4.leaderboard;"
