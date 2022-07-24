defmodule DHTTest do
  use ExUnit.Case
  doctest DHT

  test "greets the world" do
    assert DHT.hello() == :world
  end
end
