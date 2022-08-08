defmodule DHT.BucketClusterTest do

  use ExUnit.Case

  setup do
    nodes = [:a, :b, :c]

    {:ok, spawned} = ExUnited.spawn(nodes)

    nodes = for node <- nodes, do: String.to_atom(Atom.to_string(node) <> "@127.0.0.1")
    Enum.map(nodes, fn node -> :rpc.call(node, :ra, :start, []) end)

    on_exit(fn ->
      ExUnited.teardown()
    end)

    {:ok, cluster, _} = DHT.BucketCluster.start(:ra_kv, nodes)

    %{spawned: spawned, nodes: nodes, cluster: cluster}
  end

  @tag :epmd
  test "put and retrieve", %{cluster: cluster} do

    DHT.BucketRaft.put(cluster, "hey", "banana")

    assert DHT.BucketRaft.get(cluster, "hey") == {:ok, "banana"}

  end


end
