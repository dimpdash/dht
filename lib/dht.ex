defmodule DHT do
  use Application

  @impl true
  def start(_type, _args) do
    :logger.set_application_level(:ra, :none)
    DHT.Supervisor.start_link(name: DHT.Supervisor)
  end

  def add_node(node) do
    case DHT.BucketClusterManager.add_node(DHT.BucketClusterManager, node) do
      {:ok, cluster} -> DHT.Registry.add_bucket_cluster(DHT.Registry, cluster)
    end
    {:ok}
  end


end
