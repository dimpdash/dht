defmodule DHT.BucketTest do

  use ExUnit.Case, async: true

  setup do
    bucket = start_supervised!(DHT.Bucket)
    %{bucket: bucket}
  end

  # test "stores values by key", %{bucket: bucket} do
  #   assert DHT.Bucket.get(bucket, "milk") == nil

  #   DHT.Bucket.put(bucket, "milk", 3)
  #   assert DHT.Bucket.get(bucket, "milk") == 3
  # end

  # test "are temporary workers" do
  #   assert Supervisor.child_spec(DHT.Bucket, []).restart == :temporary
  # end

  # test "size", %{bucket: bucket} do
  #   assert DHT.Bucket.size(bucket) == 0
  #   DHT.Bucket.put(bucket, "milk", 3)

  #   assert DHT.Bucket.size(bucket) == 1

  #   DHT.Bucket.put(bucket, "milks", 3)

  #   assert DHT.Bucket.size(bucket) == 2

  #   DHT.Bucket.delete(bucket, "milk")


  #   assert DHT.Bucket.size(bucket) == 1

  # end

  # test "Create nodes" do
  #   Node.start(:"primary@127.0.0.1")
  #   :erl_boot_server.start([:"127.0.0.1"])
  #   node_name = "hey"
  #   {:ok, node} = :slave.start('127.0.0.1', String.to_atom(node_name), inet_loader_args())
  #   nodes = [node]

  #   # the initial cluster members
  #   members = Enum.map(nodes, fn node -> { :raft, node } end)
  #   # an arbitrary cluster name
  #   clusterName = :raft
  #   # the config passed to `init/1`, must be a `map`
  #   config = %{}
  #   # the machine configuration
  #   machine = {:module, DHT.BucketRaft, config}
  #   # ensure ra is started
  #   Application.ensure_all_started(:ra)
  #   # start a cluster instance running the `ra_kv` machine
  #   {:ok, _} = :ra.start_cluster(:default, clusterName, machine, members)
  # end

end
