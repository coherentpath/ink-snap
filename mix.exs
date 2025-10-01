defmodule InkSnap.MixProject do
  use Mix.Project

  @version "1.0.0"

  ################################
  # Public API
  ################################

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def project do
    [
      aliases: aliases(),
      app: :ink_snap,
      deps: deps(),
      description: description(),
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.18",
      name: "InkSnap",
      package: package(),
      preferred_cli_env: preferred_cli_env(),
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  ################################
  # Private API
  ################################

  defp aliases do
    [
      ci: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "test --cover --export-coverage default",
        "dialyzer --format github"
      ]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.38.4", only: :dev, runtime: false},
      {:credo, "~> 1.7.11", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.3", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.2.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Simple and lightweight snapshot testing for Elixir.
    """
  end

  defp dialyzer do
    [
      plt_local_path: "priv/plts/project.plt",
      plt_core_path: "priv/plts/core.plt",
      plt_add_apps: [:ex_unit, :mix]
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: "https://github.com/coherentpath/ink-snap",
      authors: ["Gordon Woolbert"]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Gordon Woolbert", "Nicholas Sweeting"],
      links: %{"GitHub" => "https://github.com/coherentpath/ink-snap"}
    ]
  end

  defp preferred_cli_env do
    [
      ci: :test
    ]
  end
end
