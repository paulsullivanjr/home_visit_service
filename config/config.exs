import Config

config :home_visit_service, ecto_repos: [HomeVisitService.Repo]

config :home_visit_service, HomeVisitService.Repo,
  database: "db/home_visit_service_#{Mix.env()}.db"
