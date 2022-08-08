defmodule DHT.BucketClusterManagerTest do

  use ExUnit.Case
  alias DHT
  setup do
    nodes = [:d, :e, :f, :g, :h, :i]

    {:ok, spawned} = ExUnited.spawn(nodes)

    nodes = for node <- nodes, do: String.to_atom(Atom.to_string(node) <> "@127.0.0.1")
    Enum.map(nodes, fn node -> :rpc.call(node, :ra, :start, []) end)

    on_exit(fn ->
      ExUnited.teardown()
    end)

    {:ok, cluster_manager} = BucketClusterManager.start_link([])

    %{spawned: spawned, nodes: nodes, cluster_manager: cluster_manager}
  end

  @tag :epmd
  test "add buckets", %{cluster_manager: cluster_manager, nodes: nodes} do
    {right_nodes, left_nodes} = Enum.split(nodes, 3)

    add_three(cluster_manager, right_nodes)
    add_three(cluster_manager, left_nodes)

  end

  @tag :epmd
  def add_three(cluster_manager, nodes) do
    server_ids = for node <- nodes, do: {:bucket_dyn, node}

    [node | nodes] = nodes
    BucketClusterManager.add_node(cluster_manager, node)
    {:error, :noproc} = :ra.members({:bucket_dyn, node})

    [node | nodes] = nodes
    BucketClusterManager.add_node(cluster_manager, node)
    {:error, :noproc} = :ra.members({:bucket_dyn, node})
    [node | _] = nodes
    BucketClusterManager.add_node(cluster_manager, node)

    Process.sleep(1000)

    {:ok, mems, _} = :ra.members({:bucket_dyn, node})
    assert lists_are_the_same(mems, server_ids)
  end

  defp lists_are_the_same(l1, l2) do
    Enum.sort(l1) == Enum.sort(l2)
  end

end
