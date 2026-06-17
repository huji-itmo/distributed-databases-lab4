docker exec -i cassandra-1 cqlsh -e "
CREATE TABLE lab4.leaderboard (
  game_id text,
  player_id text,
  score int,
  PRIMARY KEY (game_id)
);"
