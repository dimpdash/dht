defmodule DHT.Registry do
  use GenServer

  ## Client API

  @doc """
  Starts the registry
  """

  def start_link(opts) do
    IO.puts "here2"
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
    {:noreply, {buckets, refs}}
  end

  @impl true
  def handle_call({:put, key, value}, _from, {buckets, refs, bucket_keys}) do
    #get the partition it belongs in
    with {_, bucket_list} <- Radix.lookup(buckets, key) do
      #update all buckets
      for bucket <- bucket_list do
        DHT.Bucket.put(bucket, key, value)
      end
      {:reply, :hey, {buckets, refs, bucket_keys}}
    else
      nil -> {:reply, :error, {buckets, refs, bucket_keys}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    remove_failed_bucket(ref, state)
  end

  @doc false
  def remove_failed_bucket(ref, {buckets, refs, bucket_keys}) do
    bucket = Map.get(refs, ref)
    key = Map.get(bucket_keys, bucket)
    {_, bucket_list} = Radix.get(buckets, key)
    MapSet.delete(bucket_list, bucket)
    if MapSet.size(bucket_list) == 0 do
      Radix.delete(buckets, key)
    end

    Map.delete(refs, ref)

    {buckets, refs, bucket_keys}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in DHT.Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
