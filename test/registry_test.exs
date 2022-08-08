defmodule DHT.RegistryTest do
  use ExUnit.Case, async: false

  describe "With cluster in registry" do


    setup do
      registry = start_supervised!(DHT.Registry)

      %{cluster: cluster} = TestClusterHelper.same_node_cluster([:a, :b, :c])
      DHT.Registry.add_bucket_cluster(registry, cluster)
      %{registry: registry}
    end

    test "puts item in dht", %{registry: registry} do
      assert DHT.Registry.put(registry, "hey", "hello")
      assert DHT.Registry.get(registry, "hey") == {:ok, "hello"}
    end


  end

  describe "no cluster in registry" do
    setup do
      registry = start_supervised!(DHT.Registry)

      %{registry: registry}
    end

    test "puts item in dht", %{registry: registry} do
      assert DHT.Registry.put(registry, "hey", "hello")
      assert DHT.Registry.get(registry, "hey") == :error
    end

    test "add buckets to registry", %{registry: registry} do
      %{cluster: cluster} = TestClusterHelper.same_node_cluster([:no_clust_a, :no_clust_b, :no_clust_c])
      DHT.Registry.add_bucket_cluster(registry, cluster)

      %{cluster: cluster} = TestClusterHelper.same_node_cluster([:no_clust_d, :no_clust_e, :no_clust_f])
      DHT.Registry.add_bucket_cluster(registry, cluster)

      %{cluster: cluster} = TestClusterHelper.same_node_cluster([:no_clust_g, :no_clust_h, :no_clust_i])
      DHT.Registry.add_bucket_cluster(registry, cluster)

    end
  end


  # test "removes bucket", %{} do
  #   ref = :ref
  #   bucket_list = MapSet.new([:bucket])
  #   buckets = Radix.new([{<<0>>,bucket_list}])
  #   bucket_keys = %{bucket: <<0>>}
  #   refs = %{ref: :bucket}

  #   DHT.Registry.remove_failed_bucket(ref, %DHT.Registry.State{buckets: buckets, refs: refs, bucket_keys: bucket_keys})

  # end

  # test "split", %{} do
  #   m = MapSet.new([1,2,3,4])
  #   {first, second} = DHT.Registry.split(m)
  #   assert MapSet.size(first) == MapSet.size(second)
  #   assert MapSet.intersection(first, second) |> MapSet.size() == 0
  # end

  # test "swap last bit", %{} do
  #   bs = <<0b01001::5>>
  #   assert DHT.Registry.swap_last_bit(bs) == <<0b01000::5>>

  #   bs = <<0b01000::5>>
  #   assert DHT.Registry.swap_last_bit(bs) == <<0b01001::5>>

  #   bs = <<0b0::1>>
  #   assert DHT.Registry.swap_last_bit(bs) == <<0b1::1>>

  #   bs = <<0b1::1>>
  #   assert DHT.Registry.swap_last_bit(bs) == <<0b0::1>>
  # end

  # test "put", %{registry: registry} do
  #   key = "banana"
  #   value = "hello world"

  #   DHT.Registry.put(registry, key, value)

  #   assert DHT.Registry.get(registry, key) == value

  # end

  # test "split buckets" do
  #   state = %DHT.Registry.State{}
  #   {og_buckets, state} = DHT.Registry.spawn_buckets(state)

  #   key = <<0::1>>
  #   state = %{state | buckets: Radix.new([{key, og_buckets}])}

  #   state = DHT.Registry.split_buckets(key, state)

  #   assert {<<0b00::2>>, og_buckets} == Radix.fetch!(state.buckets, <<0b00::2>>)

  #   {_, new_buckets} = Radix.fetch!(state.buckets, <<0b01::2>>)
  #   assert state.replicate == MapSet.size(new_buckets)
  # end


  # test "merge buckets" do
  #   key = <<0b0::1>>
  #   buckets = Radix.new(
  #     [
  #      {<<0b00::2>>, MapSet.new([1])},
  #      {<<0b01::2>>, MapSet.new([2])}
  #     ]
  #   )

  #   assert DHT.Registry.merge_buckets(key, %DHT.Registry.State{buckets: buckets}).buckets == Radix.new(
  #     [
  #       {key, MapSet.new([1,2])}
  #     ]
  #   )

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
