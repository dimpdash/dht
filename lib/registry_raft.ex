defmodule DHT.RegistryRaft do
  @moduledoc """
  A raft decorator for the registry
  """

  @behaviour :ra_machine

  @me __MODULE__
  @machine_config %{}
  @side_effects []

  def process_command(cluster, command) do
    response = :ra.process_command(List.first(cluster), command)
    case response do
      {:ok, :ok, _} -> :ok
      {:ok, result, _} -> {:ok, result}
      other -> other
    end
  end

  def get(cluster, key) do
    process_command(cluster, {:get, key})
  end

  def put(cluster, key, value) do
    process_command(cluster, {:put, key, value})
  end

  @impl :ra_machine
  def init(_config), do: DHT.Registry.start_link([])

  @impl :ra_machine
  def apply(_command_meta_data, {:get, key}, state) do
    {state, DHT.Registry.get(state, key), @side_effects}
  end

  @impl :ra_machine
  def apply(_command_meta_data, {:put, key, value}, state) do
    {state, DHT.Registry.put(state, key, value), @side_effects}
  end

end

# defmodule RaftDecorator do

#   def decorate([]) do
#     quote do

#     end
#   end

#   def decorate([{module_func, func, command} | funcs]) do
#     # quote do
#     #   def unquote(func) do
#     #     process_command(cluster, unquote(command))
#     #   end
#     # end

#     quote do
#       def unquote(func) do
#         process_command(cluster, unquote(command))
#       end

#       unquote(decorate(funcs))

#       @impl :ra_machine
#       def apply(_command_metadata, unquote(command), state) do
#         {state, unquote(module_func), @side_effects}
#       end
#     end
#   end

#   def process_command(cluster, command) do
#     response = :ra.process_command(List.first(cluster), command)
#     case response do
#       {:ok, :ok, _} -> :ok
#       {:ok, result, _} -> {:ok, result}
#       other -> other
#     end
#   end


#   defmacro __using__(_opts) do

#     funcs = [
#       {quote do DHT.Registry.get(cluster, key) end, quote do get(cluster, key) end, quote do: {:get, key}},
#       {quote do DHT.Registry.put(cluster, key, value) end, quote do put(cluster, key, value) end, quote do: {:put, key, value}}
#     ]

#     quote do
#       def hey() do
#         "hey"
#       end

#       unquote(decorate(funcs))

#     #  unquote(for {func, command} <- funcs do decorate(func, command) end)
#     end
#   end


# end

# defmodule RegistryRaft do
#   use RaftDecorator
# end
