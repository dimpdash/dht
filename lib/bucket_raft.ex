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

  def migrate_keys(to_cluster, from_cluster, key \\ <<>>) do
    process_command(to_cluster, {:migrate, from_cluster, key})
  end


  def copy_tree(from_cluster, key) do
    process_command(from_cluster, {:copy, key})
  end

  def copy_tree(from_cluster) do
    process_command(from_cluster, {:copy})
  end

  def delete_keys(from_cluster, key) do
    process_command(from_cluster, {:delete_keys, key})
  end

  def process_command(cluster, command) do
    response = :ra.process_command(List.first(cluster), command)
    case response do
      {:ok, :ok, _} -> :ok
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

    @impl :ra_machine
  def apply(_command_metadata, {:migrate, from_cluster, key}, state) do

    #get keys from old cluster
    {:ok, new_tree} = copy_tree(from_cluster, key)

    #add to current tree
    state = Radix.merge(state, new_tree)


    #delete keys from the from_cluster
    :ok = delete_keys(from_cluster, key)

    key_moved_count = Radix.count(new_tree)

    {state, key_moved_count, @side_effects}
  end

  def apply(_comand_metadata, {:copy, key}, state) do
    with {:ok, new_tree} <- _copy_tree(state, key)
    do
      {state, new_tree, @side_effects}
    else
      _ -> {state, :error, @side_effects}
    end
  end

  def apply(_comand_metadata, {:copy}, state) do

    {state, state, @side_effects}
  end

  def apply(_command_metadata, {:delete_keys, key}, state) do
    {_delete_keys(state, key), :ok, @side_effects}
  end

  def _delete_keys(state, key) do
    keys = Radix.more(state, key)
      |> Enum.map(fn {key, _} -> key end)

    state = Radix.drop(state, keys)

    state
  end

  def _copy_tree(tree, key) do
    with key_values <- Radix.more(tree, key),
      new_tree <- Radix.new(key_values)
    do
      {:ok, new_tree}
    end
  end
end
