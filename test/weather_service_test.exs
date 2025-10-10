defmodule Meteo.WeatherServiceTest do
  use ExUnit.Case

  alias Meteo.WeatherService

  @api_url "https://api.open-meteo.com/v1/forecast"

  @success_response %{
    "daily" => %{
      "temperature_2m_max" => [25.0, 26.0, 27.0, 28.0, 29.0, 30.0, 31.0],
      "time" => [
        "2025-10-10",
        "2025-10-11",
        "2025-10-12",
        "2025-10-13",
        "2025-10-14",
        "2025-10-15",
        "2025-10-16"
      ]
    }
  }

  describe "get_weather_forecast/1" do
    test "returns average max temperatures for all cities" do
      Tesla.Mock.mock(fn %{url: @api_url, query: query} ->
        assert query[:latitude] in [-23.55, -19.92, -25.43]
        assert query[:longitude] in [-46.63, -43.94, -49.27]
        assert query[:daily] == "temperature_2m_max"
        assert query[:timezone] == "America/Sao_Paulo"

        {:ok, %Tesla.Env{status: 200, body: @success_response}}
      end)

      cities = [
        %{name: "São Paulo", latitude: -23.55, longitude: -46.63},
        %{name: "Belo Horizonte", latitude: -19.92, longitude: -43.94},
        %{name: "Curitiba", latitude: -25.43, longitude: -49.27}
      ]

      assert {:ok, results} = WeatherService.get_weather_forecast(cities)
      assert length(results) == 3

      for result <- results do
        assert is_binary(result.name)
        assert is_float(result.average_max_temp)
      end
    end

    test "handles API errors gracefully" do
      Tesla.Mock.mock(fn %{method: :get, url: @api_url} ->
        {:error, :timeout}
      end)

      cities = [%{name: "Test City", latitude: 0, longitude: 0}]
      assert {:error, message} = WeatherService.get_weather_forecast(cities)
      assert message =~ ":timeout for Test City"
    end
  end
end
