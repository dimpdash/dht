defmodule TestClusterHelperTest do
  use ExUnit.Case

  test "try adding same node cluster" do
    TestClusterHelper.same_node_cluster([:a, :b, :c])
  end

end
