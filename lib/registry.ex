defmodule DHT.Registry do
  defmodule State do
    defstruct [
      :buckets,
      :refs,
      :bucket_keys,
    ]
  end

  use GenServer

  ## Client API

  @doc """
  Starts the registry
  """
  def start_link(opts) do
    state = %State{}

    GenServer.start_link(__MODULE__, %{state: state, clusters: opts[:cluster]})
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
    GenServer.cast(registry, {:add_bucket_cluster, cluster})
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
  def handle_cast({:put, key, value}, state = %State{buckets: buckets}) do
    #get the partition it belongs in
    with {_, bucket_cluster} <- Radix.lookup(buckets, key) do
      #update all buckets
      DHT.BucketRaft.put(bucket_cluster, key, value)
    end
    {:noreply, state}
  end


  @impl true
  def handle_cast({:add_bucket_cluster, to_cluster}, state) do
    IO.puts "Adding cluster"
    IO.inspect to_cluster
    IO.puts "\n"
    #decide on cluster to split
    # {from_cluster, key} = get_split_candidate(state)

    # migrate keys
    # DHT.BucketRaft.migrate_keys(to_cluster, from_cluster, key)
    {:noreply, state}
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

  # def add_one_bit(bs)  do
  #   <<bs::bitstring, <<1::1>>::bitstring>>
  # end

  # def add_zero_bit(bs) do
  #   <<bs::bitstring, <<0::1>>::bitstring>>
  # end

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

  # @doc false
  # def remove_failed_bucket(ref, state = %State{buckets: buckets, refs: refs, bucket_keys: bucket_keys}) do
  #   bucket = Map.get(refs, ref)
  #   key = Map.get(bucket_keys, bucket)
  #   {_, bucket_list} = Radix.get(buckets, key)
  #   MapSet.delete(bucket_list, bucket)
  #   {bucket_list, refs} = add_bucket_back(bucket_list, refs)
  #   Radix.put(buckets, key, bucket_list)
  #   Map.delete(refs, ref)

  #   %{state | buckets: buckets, refs: refs, bucket_keys: bucket_keys}
  # end

  # def add_bucket_back(bucket_list, refs) do
  #   {:ok, bucket} = DynamicSupervisor.start_child(DHT.BucketSupervisor, DHT.Bucket)
  #   ref = Process.monitor(bucket)
  #   Map.put(refs, ref, bucket)
  #   MapSet.put(bucket_list, bucket)
  #   {bucket_list, refs}
  # end



  # defp get_split_candidate(state) do

  #   {from_cluster, key}
  # end





end
