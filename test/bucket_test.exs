defmodule DHT.BucketTest do

  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = DHT.Bucket.start_link([])
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert DHT.Bucket.get(bucket, "milk") == nil

    DHT.Bucket.put(bucket, "milk", 3)
    assert DHT.Bucket.get(bucket, "milk") == 3
  end

end
