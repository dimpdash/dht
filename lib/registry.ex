defmodule DHT.Registry do
  use GenServer

  ## Client API

  @doc """
  Starts the registry
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the bucket pid from `name` stored in `server`.any()
  Returns `{ok: pid}` if the bucket exists, `:error` otherwise.
  """

  def get(server, key) do
    GenServer.call(server, {:get, key})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`
  """

  def put(server, key, value) do
    key_hash = :crypto.hash(:sha256, key)
    GenServer.call(server, {:put, key_hash, value})
  end

  ## Define GenServer Callbacks

  @impl true
  def init(:ok) do
    buckets = Radix.new() #key to bucket pid
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
    Radix.put(buckets, <<0::256>>, pids)
    {:ok, {buckets, refs, bucket_keys}}
  end

  @impl true
  def handle_call({:get, key}, _from, {buckets, refs, bucket_keys}) do
    with {_, bucket_list} <- Radix.lookup(buckets, key) do
      val = ask_buckets_for_val(bucket_list, key)
      #reply early
      {:reply, val, {buckets, refs, bucket_keys}}
    else
      nil -> {:reply, :error, {buckets, refs, bucket_keys}}
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
  def handle_call({:put, key, value}, from, {buckets, refs, bucket_keys}) do
    #get the partition it belongs in
    with {_, bucket_list} <- Radix.lookup(buckets, key) do
      #update all buckets
      for bucket <- bucket_list do
        DHT.Bucket.put(bucket, key, value)
      end
      GenServer.reply(from, {:reply, :ok, {buckets, refs, bucket_keys}})
      {buckets, refs, bucket_keys} = check_rebalance(key, {buckets, refs, bucket_keys}, bucket_list)
      {:noreply, {buckets, refs, bucket_keys}}
    else
      nil -> {:reply, :error, {buckets, refs, bucket_keys}}
    end
  end

  def check_rebalance(key, {buckets, refs, bucket_keys}, bucket_list) do
    #check if buckets have too much in them
    size = ask_buckets_for_size(buckets)
    if size > 100 and MapSet.size(bucket_list) do
      split_buckets(key, {buckets, refs, bucket_keys}, bucket_list)
    else
      {buckets, refs, bucket_keys}
    end
  end

  def split_buckets(key, {buckets, refs, bucket_keys}, bucket_list) do
    Radix.delete(buckets, key)
    {first, second} = split(bucket_list)
    one_bit = <<1::1>>
    zero_bit = <<0::1>>
    Radix.put(buckets, <<one_bit::bitstring, key::bitstring>>, first)
    Radix.put(buckets, <<zero_bit::bitstring, key::bitstring>>,second)

    {buckets, refs, bucket_keys}
  end

  def split(list) do
    list = MapSet.to_list(list)
    len = round(length(list)/2)
    {first, second} = Enum.split(list, len)
    {MapSet.new(first), MapSet.new(second)}
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
  def remove_failed_bucket(ref, {buckets, refs, bucket_keys}) do
    bucket = Map.get(refs, ref)
    key = Map.get(bucket_keys, bucket)
    {_, bucket_list} = Radix.get(buckets, key)
    MapSet.delete(bucket_list, bucket)
    {bucket_list, refs} = add_bucket_back(bucket_list, refs)
    Radix.put(buckets, key, bucket_list)
    Map.delete(refs, ref)

    {buckets, refs, bucket_keys}
  end

  def add_bucket_back(bucket_list, refs) do
    {:ok, bucket} = DynamicSupervisor.start_child(DHT.BucketSupervisor, DHT.Bucket)
    ref = Process.monitor(bucket)
    Map.put(refs, ref, bucket)
    MapSet.put(bucket_list, bucket)
    {bucket_list, refs}
  end

end
