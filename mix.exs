defmodule CogHipchat.Mixfile do
  use Mix.Project

  def project do
    [app: :cog_hipchat,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     included_applications: [:romeo]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:cog_chat, github: "kevsmith/cog_chat"},
     {:httpotion, "~> 3.0"},
     {:romeo, github: "operable/romeo", branch: "iq-bodies"}]
  end
end
