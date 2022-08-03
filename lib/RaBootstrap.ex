defmodule RaBootstrap do
  @moduledoc false

  use GenServer

  alias RaKvstore.Config

  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_) do
    :ra.start()
    {:ok, %{}}
  end

end
