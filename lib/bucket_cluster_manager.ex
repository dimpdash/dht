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
      {_, _} -> GenServer.call(self, {:add_bucket_node, node})
      node   -> GenServer.call(self, {:add_bucket_node, {:dyn_member, node}})
    end
  end

  def start_link(opts) do
    state = %State{}
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:add_bucket_node, server_id}, _from, state = %State{spares: spares}) do
    spares = [server_id | spares]
    if length(spares) >= 3 do
      #Form new cluster
      {:ok, cluster, _} = DHT.BucketCluster.start_from_server_ids(:bucket_dyn, spares)

      DHT.Registry.add_bucket_cluster(DHT.Registry, cluster)

      {:reply, {:ok, cluster}, %{state | spares: []}}
    else
      {:reply, :ok, %{state | spares: spares}}
    end
  end

end
