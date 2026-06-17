docker exec -i cassandra-1 cqlsh -e "
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
};"
