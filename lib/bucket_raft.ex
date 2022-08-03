defmodule DHT.BucketRaft do
  @behaviour :ra_machine

  @me __MODULE__
  @machine_config %{}
  @side_effects []

  def machine_spec(), do: {:module, @me, @machine_config}

  def put(cluster, key, value) do
    process_command(cluster, {:put, key, value})
  end

  def get(cluster, key) do
    process_command(cluster, {:get, key})

  end

  def process_command(cluster, command) do
    response = :ra.process_command(List.first(cluster), command)

    case response do
      {:ok, result, _} -> {:ok, result}
      other -> other
    end
  end

  @impl :ra_machine
  def init(_config), do: Radix.new()

  @impl :ra_machine
  def apply(_command_metadata, {:get, key}, state) do
    {_, value} = Radix.get(state, key)
    {state, value, @side_effects}
  end

  @impl :ra_machine
  def apply(_command_metadata, {:put, key, value}, state) do
    {Radix.put(state, key, value), :ok, @side_effects}
  end


end
