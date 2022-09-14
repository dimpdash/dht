# DHT

**TODO: Add description**

## Process
Following https://elixir-lang.org/getting-started/mix-otp/genserver.html

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dht` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dht, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/dht>.

# Developing

## Testing 

Run all tests withouth the epmd daemon
`mix test --exclude epmd`

To run all tests need th epmd daemon running
1. `epmd -daemon`
2. `mix test`

## Running

`iex -S mix`