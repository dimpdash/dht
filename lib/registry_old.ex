defmodule DHT.RegistryOld do
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

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`
  """

  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  ## Define GenServer Callbacks

  @impl true
  def init(:ok) do
    names = %{} #name to pid
    refs = %{} #ref to name
    {:ok, {names, refs}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, state) do
    {names, _} = state
    {:reply, Map.fetch(names, name), state}
  end

  @impl true
  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, names}
    else
        {:ok, bucket} = DynamicSupervisor.start_child(DHT.BucketSupervisor, DHT.Bucket)
        ref = Process.monitor(bucket)
        refs = Map.put(refs, ref, name)
        names = Map.put(names, name, bucket)
        {:noreply, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in DHT.Registry: #{inspect(msg)}")
    {:noreply, state}
  end


end
