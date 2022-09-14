defmodule DHT.RegistryCluster do
  @moduledoc """
  Documentation for Bucket Cluster.
  """

  def start(cluster_name, nodes) do
    # ensure ra is started

    # the initial cluster members
    members = for node <- nodes, do: {cluster_name, node}

    start_from_server_ids(cluster_name, members)
  end

  def start_from_server_ids(cluster_name, server_ids) do
    # ensure ra is started

    # the config passed to `init/1`, must be a `map`
    config = %{}
    # the machine configuration
    machine = {:module, DHT.RegistryRaft, config}

    # start a cluster instance running the `ra_kv` machine
    :ra.start_cluster(:default, cluster_name, machine, server_ids)
  end

end
