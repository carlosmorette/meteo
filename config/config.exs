import Config

config :tesla, disable_deprecated_builder_warning: true

config :meteo, Meteo.WeatherService,
  api_url: "https://api.open-meteo.com/v1/forecast",
  timezone: "America/Sao_Paulo",
  days: 6

import_config("#{Mix.env()}.exs")
