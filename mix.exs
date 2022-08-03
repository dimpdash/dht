defmodule DHT.MixProject do
  use Mix.Project

  def project do
    [
      app: :dht,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {DHT, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:radix, "~> 0.4.0"},
      {:ra, "~> 2.2"},
      {:priority_queue, "~> 1.0"},
      {:ex_united, "~> 0.1.5", only: :test}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
