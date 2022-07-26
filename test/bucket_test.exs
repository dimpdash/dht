defmodule DHT.BucketTest do

  use ExUnit.Case, async: true

  setup do
    bucket = start_supervised!(DHT.Bucket)
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert DHT.Bucket.get(bucket, "milk") == nil

    DHT.Bucket.put(bucket, "milk", 3)
    assert DHT.Bucket.get(bucket, "milk") == 3
  end

  test "are temporary workers" do
    assert Supervisor.child_spec(DHT.Bucket, []).restart == :temporary
  end

end
