defmodule BucketClusterManager do
  use GenServer

  defmodule State do
    defstruct [
      :buckets, # [{cluster size,bucket cluster}]
      spares: [], # Spare buckets [node]
    ]
  end

  def test(nodes) do
    {:ok, cluster, _} = DHT.BucketCluster.start(:ra_kv2, nodes)
    cluster
  end

  def add_node(self, node) do
    GenServer.cast(self, {:add_bucket_node, node})
  end

  def start_link(_opts) do
    state = %State{}
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:add_bucket_node, node}, state = %State{spares: spares}) do
    spares = [node | spares]
    if length(spares) >= 3 do
      #Form new cluster
      {:ok, _, _} = DHT.BucketCluster.start(:bucket_dyn, spares)
      {:noreply, %{state | spares: []}}
    else
      {:noreply, %{state | spares: spares}}
    end
  end



end
