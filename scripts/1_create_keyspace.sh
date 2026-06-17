docker exec -i cassandra-1 cqlsh -e "
CREATE KEYSPACE lab4 WITH replication = {
  'class': 'NetworkTopologyStrategy',
  'dc1': 3
};"
