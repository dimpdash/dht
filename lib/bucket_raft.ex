defmodule DHT.BucketRaft do
  @behaviour :ra_machine

  @me __MODULE__
  @machine_config %{}
  @side_effects []

  def machine_spec(), do: {:module, @me, @machine_config}


  @impl :ra_machine
  def init(_config), do: Radix.new()

  @impl :ra_machine
  def apply(_command_metadata, {:get, key}, state) do
    {state, Radix.get(state, key), @side_effects}
  end

  @impl :ra_machine
  def apply(_command_metadata, {:put, key, value}, state) do
    {Radix.put(state, key, value), :ok, @side_effects}
  end

end
