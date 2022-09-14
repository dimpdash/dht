defmodule DHTTest do
  use ExUnit.Case
  doctest DHT

  setup do
    nodes = [:dht_a, :dht_b, :dht_c]

    {:ok, spawned} = ExUnited.spawn(nodes)

    nodes = for node <- nodes, do: String.to_atom(Atom.to_string(node) <> "@127.0.0.1")

    for node <- nodes do
      DHT.add_node(node)
    end

    on_exit(fn ->
      ExUnited.teardown()
    end)

    %{}
  end

  @tag :epmd
  test "put and retrieve", %{} do

    DHT.put("hey", "banana")

    assert DHT.get("hey") == {:ok, "banana"}

  end

end
