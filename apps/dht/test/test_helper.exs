ExUnit.start()
ExUnited.start(false)

defmodule TestClusterHelper do
  use ExUnit.Case

  def same_node_cluster() do

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


  def same_node_cluster(nodes) do

    server_ids = for node <- nodes, do: {node, node()}
    {:ok, _, _} = DHT.BucketCluster.start_from_server_ids(:ra_kv, server_ids)

    on_exit(fn ->
      :ra.delete_cluster(server_ids)
      for server_id <- server_ids, do: :ra.stop_server(server_id)
          Process.sleep(1000)
    end)

    %{nodes: nodes, cluster: server_ids}
  end


end
