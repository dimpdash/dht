defmodule TestClusterHelperTest do
  use ExUnit.Case

  test "try adding same node cluster" do
    TestClusterHelper.same_node_cluster([:test_cluster_helper_a, :test_cluster_helper_b, :test_cluster_helper_c])
  end

end
