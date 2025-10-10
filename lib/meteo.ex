defmodule Meteo do
  @moduledoc """
  Main module for the Meteo application that provides weather forecast information.
  """

  alias Meteo.WeatherService

  @cities [
    %{name: "São Paulo", latitude: -23.55, longitude: -46.63},
    %{name: "Belo Horizonte", latitude: -19.92, longitude: -43.94},
    %{name: "Curitiba", latitude: -25.43, longitude: -49.27}
  ]

  @doc """
  Fetches and displays the average maximum temperature forecast for the next 6 days
  for predefined Brazilian cities.

  ## Examples

      iex> {:ok, _} = Meteo.get_forecast()
      {:ok, [%{name: "São Paulo", average_max_temp: _}, ...]}

  """
  @spec get_forecast() :: {:ok, [map()]} | {:error, String.t()}
  def get_forecast do
    with {:ok, results} <- WeatherService.get_weather_forecast(@cities) do
      results = Enum.sort_by(results, & &1.average_max_temp, :desc)
      {:ok, results}
    end
  end

  @doc """
  Formats and prints the weather forecast to STDOUT.
  """
  @spec print_forecast() :: :ok
  def print_forecast do
    case get_forecast() do
      {:ok, results} ->
        results
        |> Enum.each(fn %{name: name, average_max_temp: temp} ->
          IO.puts("#{name}: #{temp}°C")
        end)

        :ok

      {:error, reason} ->
        IO.puts("Error fetching weather data: #{reason}")
        :error
    end
  end
end
