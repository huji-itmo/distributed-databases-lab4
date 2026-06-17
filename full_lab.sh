#!/usr/bin/env bash
set -e

docker compose up -d

until [ "$(docker exec cassandra-1 nodetool status 2>/dev/null | grep -c 'UN ')" -eq 3 ]; do
  echo "Waiting for all 3 nodes to be UN..."
  sleep 5
done

./scripts/1_create_keypace.sh

./scripts/2_create_table.sh

./scripts/3_seed_leaderboard.sh

docker exec -it cassandra-1 cqlsh -e 'select * from lab4.leaderboard;'
