defmodule DHT.BucketRaftTest do
  use ExUnit.Case

  setup do
    nodes = [node()]
    server_ids = [:ra_kv, node()]
    {:ok, _, _} = DHT.BucketCluster.start(:ra_kv, nodes)

    on_exit(fn ->
      :ra.delete_cluster(server_ids)
      for server_id <- server_ids, do: :ra.stop_server(server_id)
          Process.sleep(1000)
    end)

    %{nodes: nodes, cluster: server_ids}
  end

  test "put and retrieve", %{cluster: cluster} do

    :ok = DHT.BucketRaft.put(cluster, "hey", "banana")

    assert DHT.BucketRaft.get(cluster, "hey") == {:ok, "banana"}

  end

  test "migrate", %{cluster: to_cluster, nodes: nodes} do

    # create secondary cluster
    nodes = [node()]
    server_ids = [:ra_kv2, node()]
    {:ok, from_cluster, _} = DHT.BucketCluster.start(:ra_kv2, nodes)

    # populate first with some keys

    DHT.BucketRaft.put(from_cluster, <<0b000::3>>, "1")
    DHT.BucketRaft.put(from_cluster, <<0b001::3>>, "2")
    DHT.BucketRaft.put(from_cluster, <<0b111::3>>, "3")
    DHT.BucketRaft.put(from_cluster, <<0b100::3>>, "4")

    key = <<0b1::1>>
    :ok = DHT.BucketRaft.migrate_keys(to_cluster, from_cluster, key)

    {:ok, from_tree} = DHT.BucketRaft.copy_tree(from_cluster)

    {:ok, to_tree} = DHT.BucketRaft.copy_tree(to_cluster)

    assert from_tree == Radix.new([{<<0b000::3>>, "1"},{<<0b001::3>>, "2"}])
    assert to_tree == Radix.new([{<<0b111::3>>, "3"},{<<0b100::3>>, "4"}])

    #clean up created raft cluster
    for server_id <- server_ids, do: :ra.stop_server(server_id)
  end

  test "copy", %{cluster: cluster, nodes: _nodes} do
    t = Radix.new()
    t = Radix.put(t, <<0b000::3>>, "1")
    t = Radix.put(t, <<0b001::3>>, "2")
    t = Radix.put(t, <<0b011::3>>, "3")

    DHT.BucketRaft.put(cluster, <<0b000::3>>, "1")
    DHT.BucketRaft.put(cluster, <<0b001::3>>, "2")
    DHT.BucketRaft.put(cluster, <<0b011::3>>, "3")
    DHT.BucketRaft.put(cluster, <<0b100::3>>, "4")

    assert {:ok, t} == DHT.BucketRaft.copy_tree(cluster, <<0b0::1>>)
  end

  test "delete", %{cluster: cluster} do
    t = Radix.new()
    t = Radix.put(t, <<0b011::3>>, "3")
    t = Radix.put(t, <<0b100::3>>, "4")

    DHT.BucketRaft.put(cluster, <<0b000::3>>, "1")
    DHT.BucketRaft.put(cluster, <<0b001::3>>, "2")
    DHT.BucketRaft.put(cluster, <<0b011::3>>, "3")
    DHT.BucketRaft.put(cluster, <<0b100::3>>, "4")

    DHT.BucketRaft.delete_keys(cluster, <<0b00::2>>)

    assert {:ok, t} == DHT.BucketRaft.copy_tree(cluster)
  end

  def lists_are_the_same(l1, l2) do
    Enum.sort(l1) == Enum.sort(l2)
  end

end
