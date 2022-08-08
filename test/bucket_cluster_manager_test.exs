defmodule DHT.BucketClusterManagerTest do

  use ExUnit.Case
  alias DHT.BucketClusterManager
  setup do
    nodes = [:d, :e, :f, :g, :h, :i]

    server_ids = for node_id <- nodes, do: {node_id, node()}

    {:ok, cluster_manager} = BucketClusterManager.start_link([])

    %{server_ids: server_ids, cluster_manager: cluster_manager}
  end

  test "add buckets", %{cluster_manager: cluster_manager, server_ids: server_ids} do
    {right_servers, left_servers} = Enum.split(server_ids, 3)

    add_three(cluster_manager, right_servers)
    add_three(cluster_manager, left_servers)

  end

  def add_three(cluster_manager, server_ids) do
    og_server_ids = server_ids

    [server_id | server_ids] = server_ids
    BucketClusterManager.add_node(cluster_manager, server_id)
    {:error, :noproc} = :ra.members(server_id)

    [server_id | server_ids] = server_ids
    BucketClusterManager.add_node(cluster_manager, server_id)
    {:error, :noproc} = :ra.members(server_id)

    [server_id | _] = server_ids
    BucketClusterManager.add_node(cluster_manager, server_id)

    Process.sleep(1000)

    {:ok, mems, _} = :ra.members(server_id)
    assert lists_are_the_same(mems, og_server_ids)
  end

  defp lists_are_the_same(l1, l2) do
    Enum.sort(l1) == Enum.sort(l2)
  end

end
