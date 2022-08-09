defmodule DHT.RegistryTest do
  use ExUnit.Case, async: false

  describe "With cluster in registry" do


    setup do
      registry = start_supervised!(DHT.Registry)

      %{cluster: cluster} = TestClusterHelper.same_node_cluster([:registry_a, :registry_b, :registry_c])

      DHT.Registry.add_bucket_cluster(registry, cluster)
      %{registry: registry, cluster: cluster}
    end

    test "puts item in dht", %{registry: registry} do
      assert DHT.Registry.put(registry, "hey", "hello")
      assert DHT.Registry.get(registry, "hey") == {:ok, "hello"}
    end

    test "size", %{registry: registry} do
      assert 1 == DHT.Registry.get_number_of_clusters(registry)
    end

    test "remove cluster", %{registry: registry, cluster: cluster} do
      DHT.Registry.remove_cluster(registry, cluster)
      assert 0 == DHT.Registry.get_number_of_clusters(registry)
    end

  end

  describe "two clusters in registry" do
    setup do
      registry = start_supervised!(DHT.Registry)

      %{cluster: cluster1} = TestClusterHelper.same_node_cluster([:registry_a, :registry_b, :registry_c])
      %{cluster: cluster2} = TestClusterHelper.same_node_cluster([:registry2_a, :registry2_b, :registry2_c])

      DHT.Registry.add_bucket_cluster(registry, cluster1)
      DHT.Registry.add_bucket_cluster(registry, cluster2)
      %{registry: registry, cluster1: cluster1, cluster2: cluster2}
    end

    test "remove cluster", %{registry: registry, cluster1: cluster1, cluster2: cluster2} do
      assert 2 == DHT.Registry.get_number_of_clusters(registry)
      DHT.Registry.remove_cluster(registry, cluster1)
      assert 1 == DHT.Registry.get_number_of_clusters(registry)
      DHT.Registry.remove_cluster(registry, cluster2)
      assert 0 == DHT.Registry.get_number_of_clusters(registry)
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
      assert 0 == DHT.Registry.get_number_of_clusters(registry)
      %{cluster: cluster} = TestClusterHelper.same_node_cluster([:no_clust_a, :no_clust_b, :no_clust_c])
      DHT.Registry.add_bucket_cluster(registry, cluster)
      assert 1 == DHT.Registry.get_number_of_clusters(registry)

      %{cluster: cluster} = TestClusterHelper.same_node_cluster([:no_clust_d, :no_clust_e, :no_clust_f])
      DHT.Registry.add_bucket_cluster(registry, cluster)
      assert 2 == DHT.Registry.get_number_of_clusters(registry)

      %{cluster: cluster} = TestClusterHelper.same_node_cluster([:no_clust_g, :no_clust_h, :no_clust_i])
      DHT.Registry.add_bucket_cluster(registry, cluster)

      assert 3 == DHT.Registry.get_number_of_clusters(registry)
    end


  end
end
