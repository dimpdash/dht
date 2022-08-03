defmodule DHT.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {RaBootstrap, name: RaBootstrap},
      {DynamicSupervisor, name: DHT.BucketSupervisor, strategy: :one_for_one},
      {DHT.Registry, name: DHT.Registry},
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
