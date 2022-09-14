defmodule DHT do
  use Application

  @impl true
  def start(_type, _args) do
    :logger.set_application_level(:ra, :none)
    DHT.Supervisor.start_link(name: DHT.Supervisor)
  end

  def add_node(node) do
    :rpc.call(node, :ra, :start, [])
    case DHT.BucketClusterManager.add_node(DHT.BucketClusterManager, node) do
      {:ok, cluster} -> DHT.Registry.add_bucket_cluster(DHT.Registry, cluster)
      :ok -> :ok
    end
  end

  def put(key, value), do: DHT.Registry.put(DHT.Registry, key, value)

  def get(key), do: DHT.Registry.get(DHT.Registry, key)
end
