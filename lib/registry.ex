defmodule DHT.Registry do
  defmodule State do
    defstruct [
      :buckets,
      :refs,
      :key_count, # num keys (int) -> cluster
      bucket_keys: [],
    ]
  end

  use GenServer

  ## Client API

  @doc """
  Starts the registry
  """
  def start_link(opts) do
    state = %State{}

    GenServer.start_link(__MODULE__, %{state: state}, opts)
  end

  @doc """
  Looks up the bucket pid from `name` stored in `server`.any()
  Returns `{ok: pid}` if the bucket exists, `:error` otherwise.
  """

  def get(server, key) do
    key_hash = :crypto.hash(:sha256, key)
    GenServer.call(server, {:get, key_hash})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`
  """

  def put(server, key, value, :no_hash) do
    Supervisor.
    GenServer.cast(server, {:put, key, value})
  end

  @doc """
  Puts key in bucket
  Fails silently
  """
  def put(server, key, value) do
    key_hash = :crypto.hash(:sha256, key)
    GenServer.cast(server, {:put, key_hash, value})
  end

    @doc """
  Add a new bucket cluster to the registry.
  The registry will then rebalance keys
  """
  def add_bucket_cluster(registry, cluster) do
    GenServer.call(registry, {:add_bucket_cluster, cluster})
  end


  ## Define GenServer Callbacks

  @impl true
  def init(%{state: state}) do
    bucket_keys = %{} #bucket pid to key

    #create buckets
    refs = %{} # refs to bucket pid
    buckets = Radix.new([])
    {:ok, %{state | buckets: buckets, refs: refs, bucket_keys: bucket_keys}}
  end

  @impl true
  def handle_call({:get, key}, _from, state = %State{buckets: buckets}) do
    with {_, bucket_cluster} <- Radix.lookup(buckets, key) do
      val = DHT.BucketRaft.get(bucket_cluster, key)
      {:reply, val, state}
    else
      nil -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:add_bucket_cluster, cluster}, _from, state = %{buckets: buckets}) do
    if Radix.count(buckets) == 0 do
      buckets = Radix.put(buckets, <<>>, cluster)
      bucket_keys = [{0, <<>>}]
      state = %{state | buckets: buckets, bucket_keys: bucket_keys}
      {:reply, :ok, state}
    else
      # decide on cluster to split
      {state, key, from_key_count} = get_split_candidate(state)
      {_, from_cluster} = Radix.fetch!(buckets, key)

      #new keys
      from_key = add_zero_bit(key)
      to_key = add_one_bit(key)

      # migrate keys
      {:ok, key_moved_count} = DHT.BucketRaft.migrate_keys(cluster, from_cluster, to_key)
      IO.puts "############################"
      IO.inspect key_moved_count
      #Update the key priority tree
      to_key_count = key_moved_count #Assumes no keys in "to" bucket cluster
      from_key_count = from_key_count - key_moved_count

      bucket_keys = state.bucket_keys
      bucket_keys = [{from_key_count, from_key} | bucket_keys]
      bucket_keys = [{to_key_count, to_key} | bucket_keys]

      buckets = Radix.put(buckets, [{from_key, from_cluster},{to_key, cluster}])
      {:reply, :ok, %{state | buckets: buckets, bucket_keys: bucket_keys}}
    end
  end


  @impl true
  def handle_cast({:put, key, value}, state = %State{buckets: buckets}) do
    #get the partition it belongs in

   with {_, bucket_cluster} <- Radix.lookup(buckets, key) do
      #update all buckets
      DHT.BucketRaft.put(bucket_cluster, key, value)

      state = increment_list(state, key)
      {:noreply, state}
    end
    {:noreply, state}
  end

  defp increment_list(state = %State{bucket_keys: bucket_keys}, key) do
    {{count, val}, bucket_keys} = Find.take_first_match(bucket_keys, key)
    count = count + 1
    bucket_keys = [{count, val} | bucket_keys]
    %{state | bucket_keys: bucket_keys}
  end



  defp get_split_candidate(state = %State{bucket_keys: bucket_keys}) do
    [{from_key_count, key} | bucket_keys] = Enum.sort(bucket_keys, :desc)

    {%{state | bucket_keys: bucket_keys}, key, from_key_count}
  end

  # def merge_buckets(key, state = %State{buckets: buckets}) do
  #   keys_to_merge = Radix.more(buckets, key)

  #   pids = Enum.reduce(
  #     keys_to_merge,
  #     MapSet.new(),
  #     fn {_, child_buckets}, acc -> MapSet.union(acc, child_buckets) end
  #   )
  #   keys = for {child_key, _} <- keys_to_merge, do: child_key

  #   buckets = buckets
  #     |> Radix.put(key, pids)
  #     |> Radix.drop(keys)

  #   %{state | buckets: buckets}
  # end

  def add_one_bit(bs)  do
    <<bs::bitstring, <<1::1>>::bitstring>>
  end

  def add_zero_bit(bs) do
    <<bs::bitstring, <<0::1>>::bitstring>>
  end

  # def swap_last_bit(bs) do
  #   size = bit_size(bs) - 1
  #   <<head :: size(size), bit :: 1>> = bs

  #   <<head :: size(size), Bitwise.bnot(bit) :: 1>>
  # end

  # def get_parent(key) do
  #   size = bit_size(key) - 1
  #   <<head :: size(size), _bit :: 1>> = key

  #   <<head :: size(size)>>
  # end

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

  @doc """
  Finds the first element in a list to match a given pattern.
  """
  def take_first_match(collection, item) do
    i = Enum.find_index(collection, fn({_, element2}) ->
      element2 == item
    end)

    List.pop_at(collection, i)
  end

end
