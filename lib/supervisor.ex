defmodule DHT.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {RaBootstrap, name: RaBootstrap},
      {DHT.Registry, name: DHT.Registry},
      {DHT.BucketClusterManager, name: DHT.BucketClusterManager},
      {DynamicSupervisor, name: DHT.BucketSupervisor, strategy: :one_for_one},
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
