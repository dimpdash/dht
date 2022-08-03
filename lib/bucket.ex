defmodule DHT.Bucket do
  use Agent, restart: :temporary


  @doc """
  Starts a new bucket
  """

  def start_link(_opts) do
    Agent.start_link(fn -> Radix.new() end)
  end

  @doc """
    Gets a value from the `bucket` by `key`
  """

  def get(bucket, key) do
    Agent.get(bucket, &Radix.get(&1, key))
  end

  @doc """
  Get all `{key, value}` pairs as radix tree with prefix equal to or longer than `key`
  """
  def get_tree(bucket, key) do
    Agent.get(bucket, fn tree ->
      Radix.take(tree, Radix.more(tree, key))
    end
    )
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Radix.put(&1, key, value))
  end

  @doc """
  Migrates `{key, value}` pairs from buckets to this bucket;
  if the `key` is greater than or equal to the given `key`
  """
  def migrate(bucket, old_buckets, key) do
    Agent.cast(bucket, fn tree ->
      old_buckets
      |> Enum.map(fn b -> DHT.Bucket.get_tree(b, key) end)
      |> Enum.reduce(tree, fn t, acc -> Radix.merge(t, acc) end)
    end)
  end

  @doc """
  Deletes `key` from `bucket`

  Returns the current value of `key`, if `key` exists
  """

  def delete(bucket, key) do
    Agent.get_and_update(bucket, fn dict ->
      Radix.pop(dict, key)
    end)
  end

  @doc """
  Delete keys with prefix longer than or equal to `key`
  """
  def delete_above(bucket, key) do
    Agent.update(
      bucket,
      fn tree ->
        Radix.drop(tree, Radix.more(tree, key))
      end
    )
  end


  @doc """
  Gets the number of `{key, value}` pairs
  """
  def size(bucket) do
    Agent.get(bucket, fn dict ->
      Kernel.length(Radix.to_list(dict))
    end)
  end

end
