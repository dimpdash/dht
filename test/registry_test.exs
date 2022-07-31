defmodule DHT.RegistryTest do
  use ExUnit.Case, async: false

  setup do
    registry = start_supervised!(DHT.Registry)
    %{registry: registry}
  end

  # test "puts item in dht", %{registry: registry} do
  #   assert DHT.Registry.get(registry, "hey")
  # end

  test "removes bucket", %{} do
    ref = :ref
    bucket_list = MapSet.new([:bucket])
    buckets = Radix.new([{<<0>>,bucket_list}])
    bucket_keys = %{bucket: <<0>>}
    refs = %{ref: :bucket}

    DHT.Registry.remove_failed_bucket(ref, %DHT.Registry.State{buckets: buckets, refs: refs, bucket_keys: bucket_keys})

  end

  test "split", %{} do
    m = MapSet.new([1,2,3,4])
    {first, second} = DHT.Registry.split(m)
    assert MapSet.size(first) == MapSet.size(second)
    assert MapSet.intersection(first, second) |> MapSet.size() == 0
  end

  test "swap last bit", %{} do
    bs = <<0b01001::5>>
    assert DHT.Registry.swap_last_bit(bs) == <<0b01000::5>>

    bs = <<0b01000::5>>
    assert DHT.Registry.swap_last_bit(bs) == <<0b01001::5>>

    bs = <<0b0::1>>
    assert DHT.Registry.swap_last_bit(bs) == <<0b1::1>>

    bs = <<0b1::1>>
    assert DHT.Registry.swap_last_bit(bs) == <<0b0::1>>
  end

  test "merge buckets", %{} do
    key1 = <<0b01::2>>
    buckets1 = MapSet.new([:a])
    key2 = <<0b00::2>>
    buckets2 = MapSet.new([:b])
    pair1 = {key1, buckets1}
    pair2 = {key2, buckets2}
    tree = Radix.new([pair1, pair2])

    assert DHT.Registry.merge_buckets(<<0b01::2>>, %{buckets: tree})
  end

  test "put", %{registry: registry} do
    key = "banana"
    value = "hello world"

    DHT.Registry.put(registry, key, value)

    assert DHT.Registry.get(registry, key) == value

  end

  # test "split buckets" do


  # end

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
