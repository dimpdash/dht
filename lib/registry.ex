defmodule RegistryState do
  @moduledoc """
  Implments a birdirectional map to find key bucket pairs along with keeping track of keys inserted in the bucket cluster
  """
  defstruct [
    :keys_to_buckets,
    :buckets_to_keys,
    bucket_keys_count: [],
  ]

  def new() do
    %RegistryState{
      keys_to_buckets: Radix.new([]),
      buckets_to_keys: %{},
      bucket_keys_count: [],
    }
  end

  @doc"""
  Lookup the cluster with the longer key prefix match

  This is done with a Radix tree
  """
  def lookup_cluster(%RegistryState{keys_to_buckets: keys_to_buckets}, key) do
    Radix.lookup(keys_to_buckets, key)
  end

  @doc"""
  Get the key for a cluster
  """
  def get_key_prefix(%RegistryState{buckets_to_keys: buckets_to_keys}, cluster) do
    Map.get(buckets_to_keys, cluster)
  end

  @doc"""
  Increment the number of keys a bucket holds
  """
  def increment_keys(state = %{bucket_keys_count: bucket_keys_count}, key) do
    {{count, val}, bucket_keys_count} = Find.take_first_match(bucket_keys_count, key)
    count = count + 1
    bucket_keys_count = [{count, val} | bucket_keys_count]
    %{state | bucket_keys_count: bucket_keys_count}
  end

  @doc"""
  Takes one of the maximum clusters with the maximum keys.
  The cluster is then removed from the keys list
  """
  def take_max_key_cluster(state = %RegistryState{bucket_keys_count: bucket_keys_count}) do
    [{from_key_count, key} | bucket_keys_count] = Enum.sort(bucket_keys_count, :desc)
    {_, cluster} = Radix.get(state.keys_to_buckets, key)

    state = %RegistryState{
      bucket_keys_count: bucket_keys_count,
      keys_to_buckets: Radix.drop(state.keys_to_buckets, [key]),
      buckets_to_keys: Map.drop(state.buckets_to_keys, [cluster])
    }

    {state, key, from_key_count, cluster}
  end

  @doc"""
  Add a bucket cluster
  """
  def add_bucket(state = %RegistryState{
    bucket_keys_count: bucket_keys_count,
    keys_to_buckets: keys_to_buckets,
    buckets_to_keys: buckets_to_keys},
    key, cluster, num_keys \\ 0) do

    bucket_keys_count = [{num_keys, key} | bucket_keys_count]
    buckets_to_keys = Map.put(buckets_to_keys, cluster, key)
    keys_to_buckets = Radix.put(keys_to_buckets, [{key, cluster}])
    %{state |
      keys_to_buckets: keys_to_buckets,
      bucket_keys_count: bucket_keys_count,
      buckets_to_keys: buckets_to_keys
    }
  end

  @doc"""
  Fetch cluster from key
  """
  def fetch_cluster!(%RegistryState{keys_to_buckets: keys_to_buckets}, key) do
    Radix.fetch!(keys_to_buckets, key)
  end

  @doc"""
  Update the key prefix the bucket cluster should hold
  """
  def update_key(state = %RegistryState{}, from_key, to_key, cluster \\ nil) do
    cluster = case cluster do
      nil -> Radix.get(state.keys_to_buckets, from_key)
      _ -> cluster
    end

    %{state |
      keys_to_buckets:   Radix.update(state.keys_to_buckets, from_key, fn {_, value} -> {to_key , value} end),
      buckets_to_keys:   Map.update!(state.buckets_to_keys, cluster , fn {cluster, _} -> {cluster, to_key} end),
      bucket_keys_count: Find.update(state.bucket_keys_count, from_key, fn {key_count, _} -> {key_count, to_key} end)
    }
  end

  @doc """
  Get the number of buckets/keys
  """
  def size(state = %RegistryState{keys_to_buckets: keys_to_buckets}) do
    Radix.count(keys_to_buckets)
  end


  @typedoc """
  A cluster of server ids
  """
  @type cluster :: [:ra.server_id()]

  @typedoc"""
  A bitstring used as a key to index into the radix tree.

  During tree traversals, bit positions in the key are checked in order
  to decide whether to go left (0) or right (1).  During these checks, bits
  beyond the current key's length always evaluate to 0.

  """
  @type key :: bitstring()

  @doc"""
  Remove cluster
  """
  def remove_cluster(state = %RegistryState{}, cluster) do
    key = Map.get(state.buckets_to_keys, cluster)

    {_, bucket_keys_count} = Find.take_first_match(state.bucket_keys_count, key)
    state = %{ state |
      buckets_to_keys: Map.drop(state.buckets_to_keys, cluster),
      keys_to_buckets: Radix.drop(state.keys_to_buckets, [key]),
      bucket_keys_count: bucket_keys_count,
    }

    state
  end

  @doc"""
  Get the closest neighbour to a key
  """
  def get_closest_neighbour(state = %RegistryState{}, key) do
    parent_key = Key.get_parent(key)
    if parent_key == nil do
      nil
    else
      case Radix.more(state.keys_to_buckets, parent_key) do
        [{^key, _}, neighbour] -> {neighbour, parent_key}
        [neighbour, {^key, _}] -> {neighbour, parent_key}
        _ -> nil
      end
    end

  end

end

defmodule DHT.Registry do

  use GenServer

  ## Client API

  @doc"""
  Starts the registry
  """
  def start_link(opts) do
    state = RegistryState.new()

    GenServer.start_link(__MODULE__, %{state: state}, opts)
  end

  @doc"""
  Looks up the bucket pid from `name` stored in `server`.any()
  Returns `{ok: pid}` if the bucket exists, `:error` otherwise.
  """

  def get(server, key) do
    key_hash = :crypto.hash(:sha256, key)
    GenServer.call(server, {:get, key_hash})
  end

  @doc"""
  Ensures there is a bucket associated with the given `name` in `server`
  """

  def put(server, key, value, :no_hash) do
    GenServer.cast(server, {:put, key, value})
  end

  @doc"""
  Puts key in bucket
  Fails silently
  """
  def put(server, key, value) do
    key_hash = :crypto.hash(:sha256, key)
    GenServer.cast(server, {:put, key_hash, value})
  end

  @doc"""
  Add a new bucket cluster to the registry.
  The registry will then rebalance keys
  """
  def add_bucket_cluster(registry, cluster) do
    GenServer.call(registry, {:add_bucket_cluster, cluster})
  end

  @doc"""
  Remove a cluster from the registry
  """
  def remove_cluster(registry, cluster) do
    GenServer.cast(registry, {:remove_cluster, cluster})
  end

  @doc"""
  Get the number of clusters
  """
  def get_number_of_clusters(registry) do
    GenServer.call(registry, {:number_of_clusters})
  end

  ## Define GenServer Callbacks

  @impl true
  def init(%{state: state}) do
    {:ok, state}
  end

  @impl true
  def handle_call({:number_of_clusters}, _from, state = %RegistryState{}) do
    {:reply, RegistryState.size(state), state}
  end

  @impl true
  def handle_call({:get, key}, _from, state = %RegistryState{}) do
    with {_, bucket_cluster} <- RegistryState.lookup_cluster(state, key) do
      val = DHT.BucketRaft.get(bucket_cluster, key)
      {:reply, val, state}
    else
      nil -> {:reply, :error, state}
    end
  end
  :ra

  @impl true
  def handle_call({:add_bucket_cluster, to_cluster}, _from, state = %RegistryState{}) do
    if RegistryState.size(state) == 0 do
      state = RegistryState.add_bucket(state, <<>>, to_cluster)
      {:reply, :ok, state}
    else
      # decide on cluster to split
      {state, key, from_key_count, from_cluster} = get_split_candidate(state)

      #new keys
      from_key = Key.add_zero_bit(key)
      to_key = Key.add_one_bit(key)

      # migrate keys
      {:ok, key_moved_count} = DHT.BucketRaft.migrate_keys(to_cluster, from_cluster, to_key)

      #Update the key priority tree
      to_key_count = key_moved_count #Assumes no keys in "to" bucket cluster
      from_key_count = from_key_count - key_moved_count

      state = RegistryState.add_bucket(state, to_key, to_cluster, to_key_count)
      state = RegistryState.add_bucket(state, from_key, from_cluster, from_key_count)

      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_cast({:put, key, value}, state = %RegistryState{}) do
    #get the partition it belongs in


   with {bucket_key, bucket_cluster} <- RegistryState.lookup_cluster(state, key) do
      #update all buckets
      DHT.BucketRaft.put(bucket_cluster, key, value)

      RegistryState.increment_keys(state, bucket_key)

      {:noreply, state}
    end
    {:noreply, state}
  end

  def handle_cast({:remove_cluster, from_cluster}, state = %RegistryState{}) do
    #migrate

    from_key = RegistryState.get_key_prefix(state, from_cluster)

    state = RegistryState.remove_cluster(state, from_cluster)

    with {{to_key, to_cluster}, parent_key} <- get_merge_candidate(state, from_key) do
      state = RegistryState.update_key(state, to_key, parent_key)
      DHT.BucketRaft.migrate_keys(to_cluster, from_cluster)
      {:noreply, state}
    else
      #Warning the keys will be lost
      nil -> {:noreply, state}
    end
  end

  def get_merge_candidate(state = %RegistryState{}, from_key) do
    RegistryState.get_closest_neighbour(state, from_key)
  end

  defp get_split_candidate(state = %RegistryState{}) do
    RegistryState.take_max_key_cluster(state)
  end





  # def split(list) do
  #   list = MapSet.to_list(list)
  #   len = round(length(list)/2)
  #   {first, second} = Enum.split(list, len)
  #   {MapSet.new(first), MapSet.new(second)}
  # end

  # @impl true
  # def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
  #   remove_failed_bucket(ref, state)
  # end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in DHT.Registry: #{inspect(msg)}")
    {:noreply, state}
  end

end

defmodule Find do
  @moduledoc """
  Implements methods to find elements in given collections by pattern matching.
  """

  def find_at(collection, item) do
    Enum.find_index(collection, fn({_, element2}) ->
      element2 == item
    end)
  end

  @doc """
  Finds the first element in a list to match a given pattern.
  """
  def take_first_match(collection, item) do
    i = find_at(collection, item)
    List.pop_at(collection, i)
  end

  def update(collection, item, func) do
    {item, collection} = take_first_match(collection, item)
    [func.(item) | collection]
  end

end

defmodule Key do
  # def swap_last_bit(bs) do
  #   size = bit_size(bs) - 1
  #   <<head :: size(size), bit :: 1>> = bs

  #   <<head :: size(size), Bitwise.bnot(bit) :: 1>>
  # end

  @spec get_parent(RegistryState.key) :: RegistryState.key | nil
  def get_parent(key) do
    case key do
      <<>> -> nil
      _ ->
          size = bit_size(key) - 1
          <<head :: size(size), _bit :: 1>> = key
          <<head :: size(size)>>

    end
  end

  def add_one_bit(bs)  do
    <<bs::bitstring, <<1::1>>::bitstring>>
  end

  def add_zero_bit(bs) do
    <<bs::bitstring, <<0::1>>::bitstring>>
  end
end
