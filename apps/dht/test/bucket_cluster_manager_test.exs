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
    :ok = BucketClusterManager.add_node(cluster_manager, server_id)
    {:error, :noproc} = :ra.members(server_id)

    [server_id | server_ids] = server_ids
    :ok = BucketClusterManager.add_node(cluster_manager, server_id)
    {:error, :noproc} = :ra.members(server_id)

    [server_id | _] = server_ids
    {:ok, created_cluster} = BucketClusterManager.add_node(cluster_manager, server_id)

    Process.sleep(1000)

    {:ok, mems, _} = :ra.members(server_id)
    assert lists_are_the_same(mems, og_server_ids)
    assert lists_are_the_same(created_cluster, og_server_ids)



  end

  defp lists_are_the_same(l1, l2) do
    Enum.sort(l1) == Enum.sort(l2)
  end



end

defmodule RegistryMock do
  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call({:add_bucket_cluster, to_cluster}, state) do
    IO.puts "###########################I'm Alive#######################################"
    IO.puts "Adding cluster"
    IO.inspect to_cluster
    IO.puts "\n"
    #decide on cluster to split
    # {from_cluster, key} = get_split_candidate(state)

    # migrate keys
    # DHT.BucketRaft.migrate_keys(to_cluster, from_cluster, key)
    {:reply, :ok, state}
  end
end
