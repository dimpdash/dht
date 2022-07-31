defmodule DHT.Registry do
  defmodule State do
    defstruct [
      :buckets,
      :refs,
      :bucket_keys,
      target_bucket_size: 2
    ]
  end

  use GenServer

  ## Client API

  @doc """
  Starts the registry
  """

  def start_link(opts) do
    state = %State{target_bucket_size: Keyword.get(opts, :target_bucket_size, 2)}
    GenServer.start_link(__MODULE__, state)
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
    GenServer.cast(server, {:put, key, value})
  end

  def put(server, key, value) do
    key_hash = :crypto.hash(:sha256, key)
    GenServer.cast(server, {:put, key_hash, value})
  end

  ## Define GenServer Callbacks

  @impl true
  def init(state) do
    bucket_keys = %{} #bucket pid to key
    #TODO change if have multiple registries
    #create buckets
    refs = %{} # refs to bucket pid
    pids = for _ <- 1..10 do
      {:ok, bucket} = DynamicSupervisor.start_child(DHT.BucketSupervisor, DHT.Bucket)
      ref = Process.monitor(bucket)
      Map.put(refs, ref, bucket)
      #Add to list
      bucket
    end
    {left, right} = Enum.split(pids, round(length(pids)/2))
    buckets = Radix.new(
      [
        {<<0::1>>, MapSet.new(left)},
        {<<1::1>>, MapSet.new(right)}
      ]
    )
    {:ok, %{state | buckets: buckets, refs: refs, bucket_keys: bucket_keys}}
  end

  @impl true
  def handle_call({:get, key}, _from, state = %State{buckets: buckets}) do
    with {_, bucket_list} <- Radix.lookup(buckets, key) do
      val = ask_buckets_for_val(MapSet.to_list(bucket_list), key)
      #reply early
      {:reply, val, state}
    else
      nil -> {:reply, :error, state}
    end
  end

  def ask_buckets_for_val([bucket | buckets], key) do
    case DHT.Bucket.get(bucket, key) do
      nil -> ask_buckets_for_val(buckets, key)
      val -> val
    end
  end

  def ask_buckets_for_size([bucket | buckets]) do
    case DHT.Bucket.size(bucket) do
      nil -> ask_buckets_for_size(buckets)
      val -> val
    end
  end

  @impl true
  def handle_cast({:put, key, value}, state = %State{buckets: buckets}) do
    #get the partition it belongs in
    with {_, bucket_list} <- Radix.lookup(buckets, key) do
      #update all buckets
      for bucket <- bucket_list do
        DHT.Bucket.put(bucket, key, value)
      end
      {:noreply, state}
    end
  end

  def check_rebalance(key, state = %State{}, bucket_list) do
    #check if buckets have too much in them
    size = ask_buckets_for_size(MapSet.to_list(bucket_list))
    cond do
      size > state.target_bucket_size ->
        split_buckets(key, state, bucket_list)

      #TODO handle merging

      true ->
        state
    end
  end

  def split_buckets(key, state = %State{buckets: buckets}, bucket_list) do
    Radix.delete(buckets, key)
    {first, second} = split(bucket_list)

    buckets
      |> Radix.put(add_one_bit(key), first)
      |> Radix.put(add_zero_bit(key),second)

    %{state | buckets: buckets}
  end

  def add_one_bit(bs)  do
    <<bs::bitstring, <<1::1>>::bitstring>>
  end

  def add_zero_bit(bs) do
    <<bs::bitstring, <<0::1>>::bitstring>>
  end

  def swap_last_bit(bs) do
    size = bit_size(bs) - 1
    <<head :: size(size), bit :: 1>> = bs

    <<head :: size(size), Bitwise.bnot(bit) :: 1>>
  end

  def get_parent(key) do
    size = bit_size(key) - 1
    <<head :: size(size), _bit :: 1>> = key

    <<head :: size(size)>>
  end

  def split(list) do
    list = MapSet.to_list(list)
    len = round(length(list)/2)
    {first, second} = Enum.split(list, len)
    {MapSet.new(first), MapSet.new(second)}
  end

  def merge_buckets(key, state = %{buckets: buckets}) do
    left = Radix.get(buckets, swap_last_bit(key))

    if left != nil do
      {_, left_buckets} = left
      parent = get_parent(key)
      {_, right_buckets} = Radix.fetch!(buckets, key)
      buckets_merged = MapSet.union(left_buckets, right_buckets)
      Radix.put(buckets, parent, buckets_merged)
      Radix.drop(buckets, [key])
    end

    %{state | buckets: buckets}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    remove_failed_bucket(ref, state)
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in DHT.Registry: #{inspect(msg)}")
    {:noreply, state}
  end

  @doc false
  def remove_failed_bucket(ref, state = %State{buckets: buckets, refs: refs, bucket_keys: bucket_keys}) do
    bucket = Map.get(refs, ref)
    key = Map.get(bucket_keys, bucket)
    {_, bucket_list} = Radix.get(buckets, key)
    MapSet.delete(bucket_list, bucket)
    {bucket_list, refs} = add_bucket_back(bucket_list, refs)
    Radix.put(buckets, key, bucket_list)
    Map.delete(refs, ref)

    %{state | buckets: buckets, refs: refs, bucket_keys: bucket_keys}
  end

  def add_bucket_back(bucket_list, refs) do
    {:ok, bucket} = DynamicSupervisor.start_child(DHT.BucketSupervisor, DHT.Bucket)
    ref = Process.monitor(bucket)
    Map.put(refs, ref, bucket)
    MapSet.put(bucket_list, bucket)
    {bucket_list, refs}
  end

end
