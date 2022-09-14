# Dht
A distributed hash table using raft for fault tolerance

## Developing 
Start the main registry
`cd ./apps/dht`
`iex --sname master -S mix`

Start the raft servers

`cd ./apps/raft_server`
`iex --sname master -S mix`

## Testing
ensure epmd is running in the background
`epmd --daemon`
then can test
`mix test`

if epmd is not running in the background can exclude tests. Was not able get epmd running on windows instead can use WSL.

`mix test --exclude epmd`
