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
end
