import Config

config :home_visit_service, HomeVisitService.Repo,
  database: Path.expand("../home_visit_service_dev.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  show_sensitive_data_on_connection_error: true
