defmodule HomeVisitService.MixProject do
  use Mix.Project

  def project do
    [
      app: :home_visit_service,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_options: [
        warnings_as_errors: true
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {HomeVisitService.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.15.1"},
      {:faker, "~> 0.18.0"}
    ]
  end
end
