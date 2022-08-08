defmodule DHT.BucketClusterManager do
  use GenServer

  defmodule State do
    defstruct [
      :buckets, # [{cluster size,bucket cluster}]
      spares: [], # Spare buckets [node]
    ]
  end

  def add_node(self, node) do
    case node do
      #if a server id. ie node hostname is second argument
      {_, _} -> GenServer.cast(self, {:add_bucket_node, node})
      node   -> GenServer.cast(self, {:add_bucket_node, {:dyn_member, node}})
    end
  end

  def start_link(_opts) do
    state = %State{}
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:add_bucket_node, server_id}, state = %State{spares: spares}) do
    spares = [server_id | spares]
    if length(spares) >= 3 do
      #Form new cluster
      {:ok, cluster, _} = DHT.BucketCluster.start_from_server_ids(:bucket_dyn, spares)
      DHT.Registry.add_bucket_cluster(DHT.Registry, cluster)
      {:noreply, %{state | spares: []}}
    else
      {:noreply, %{state | spares: spares}}
    end
  end




end
