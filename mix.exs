defmodule DualMap.MixProject do
  use Mix.Project

  def project do
    [
      app: :dual_map_ex,
      version: "0.1.2",
      elixir: "~> 1.17",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      description: "A simple dual-entry map",
      package: package(),
      deps: deps()
    ]
  end

  def package do
    [
      maintainers: ["Mauricio Santecchia"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mailcmd/dual_map_ex"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
