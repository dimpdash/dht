defmodule RaftServerTest do
  use ExUnit.Case
  doctest RaftServer

  test "greets the world" do
    assert RaftServer.hello() == :world
  end
end
