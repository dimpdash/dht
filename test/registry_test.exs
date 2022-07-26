defmodule DHT.RegistryTest do
  use ExUnit.Case, async: true

  setup do
    registry = start_supervised!(DHT.Registry)
    %{registry: registry}
  end

  # test "puts item in dht", %{registry: registry} do
  #   assert DHT.Registry.get(registry, "hey")
  # end

  test "puts item in dht with no buckets", %{registry: registry} do
    assert DHT.Registry.put(registry, "hello", "world") == :error
  end

  test "removes bucket", %{} do
    ref = :ref
    bucket_list = MapSet.new([:bucket])
    buckets = Radix.new([{<<0>>,bucket_list}])
    bucket_keys = %{bucket: <<0>>}
    refs = %{ref: :bucket}

    DHT.Registry.remove_failed_bucket(ref, {buckets, refs, bucket_keys})

  end

  test "split", %{} do
    m = MapSet.new([1,2,3,4])
    {first, second} = DHT.Registry.split(m)
    assert MapSet.size(first) == MapSet.size(second)
    assert MapSet.intersection(first, second) |> MapSet.size() == 0
  end

  # test "spawns buckets", %{registry: registry} do
  #   assert DHT.Registry.lookup(registry, "shopping") == :error

  #   DHT.Registry.create(registry, "shopping")
  #   assert {:ok, bucket} = DHT.Registry.lookup(registry, "shopping")

  #   DHT.Bucket.put(bucket, "milk", 1)
  #   assert DHT.Bucket.get(bucket, "milk") == 1
  # end

  # test "removes buckets on exit", %{registry: registry} do
  #   DHT.Registry.create(registry, "shopping")
  #   {:ok, bucket} = DHT.Registry.lookup(registry, "shopping")
  #   Agent.stop(bucket)
  #   assert DHT.Registry.lookup(registry, "shopping") == :error
  # end

  # test "removes bucket on crash", %{registry: registry} do
  #   DHT.Registry.create(registry, "shopping")
  #   {:ok, bucket} = DHT.Registry.lookup(registry, "shopping")

  #   #Stop the bucket with non-normal reason
  #   Agent.stop(bucket, :shutdown)
  #   assert DHT.Registry.lookup(registry, "shopping") == :error
  # end
end
