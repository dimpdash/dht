defmodule DHT do
  use Application

  @impl true
  def start(_type, _args) do
    DHT.Supervisor.start_link(name: DHT.Supervisor)
  end
end
