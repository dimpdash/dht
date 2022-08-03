defmodule DHT.BucketClusterTest do

  use ExUnit.Case

  setup do
    nodes = [:a, :b, :c]

    {:ok, spawned} = ExUnited.spawn(nodes)

    nodes = [:"a@127.0.0.1", :"b@127.0.0.1"]
    Enum.map(nodes, fn node -> Node.spawn(node, &:ra.start/0) end)

    on_exit(fn ->
      ExUnited.teardown()
    end)

    %{spawned: spawned, nodes: nodes}
  end

  test "run", %{nodes: nodes} do
    {:ok, _, _} = DHT.BucketCluster.start(:ra_kv, nodes)
  end


end
