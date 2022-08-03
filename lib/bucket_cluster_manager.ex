defmodule BucketClusterManager do
  defmodule State do
    defstruct [
      :buckets, # [{cluster size,bucket cluster}]
    ]
  end

  @doc """
  Add a new bucket node
  """
  def join(node) do

  end


  def handle_cast({:add_bucket_node, node}, state = %State{buckets: buckets}) do

    [{size, cluster} | buckets] = buckets

    :ra.add_member({:bucket_cluster, node}, cluster)

    buckets = [{size+1,cluster} | buckets]

    buckets = List.keysort(buckets, 0)

    %State{state | buckets: buckets}

  end

  def handle_cast({:bucket_leave, _node}, state = %State{}) do
    state
  end

end
