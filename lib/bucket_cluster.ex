defmodule DHT.BucketCluster do
  @moduledoc """
  Documentation for Bucket Cluster.
  """

  def start(cluster_name, nodes) do
    # ensure ra is started
    :ra.start()
    # the initial cluster members
    members = for node <- nodes, do: {cluster_name, node }
    # the config passed to `init/1`, must be a `map`
    config = %{}
    # the machine configuration
    machine = {:module, DHT.BucketRaft, config}

    # start a cluster instance running the `ra_kv` machine
    :ra.start_cluster(:default, cluster_name, machine, members)
  end

end
