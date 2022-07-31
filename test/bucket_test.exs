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

  test "size", %{bucket: bucket} do
    assert DHT.Bucket.size(bucket) == 0
    DHT.Bucket.put(bucket, "milk", 3)

    assert DHT.Bucket.size(bucket) == 1

    DHT.Bucket.put(bucket, "milks", 3)

    assert DHT.Bucket.size(bucket) == 2

    DHT.Bucket.delete(bucket, "milk")


    assert DHT.Bucket.size(bucket) == 1

  end

end
