defmodule Rooms.MixProject do
  use Mix.Project

  def project do
    [
      app: :rooms,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Rooms.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gamenite_persistance, in_umbrella: true},
      {:phoenix_pubsub, "~> 2.0"},
      {:accessible, "~> 0.3.0"},
      {:poison, "~> 5.0"},
      {:membrane_rtc_engine, github: "membraneframework/membrane_rtc_engine"},
      {:membrane_core, github: "membraneframework/membrane_core", override: true},
      {:membrane_rtp_plugin, github: "membraneframework/membrane_rtp_plugin"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
    ]
  end
end
