#!/usr/bin/env bash
set -e
docker exec -i cassandra-1 bash << 'SCRIPT'
for i in $(seq 1 100); do
  cqlsh -e "INSERT INTO lab4.compaction_test (game_id, player_id, score) VALUES ('game_triple_t', 'player_$i', $i);"
  nodetool flush lab4 compaction_test
  echo "$i/100"
done
SCRIPT
