defmodule Meteo.WeatherService do
  @moduledoc """
  Module responsible for fetching weather data and calculating statistics.
  """

  @config Application.compile_env(:meteo, Meteo.WeatherService)
  @api_url @config[:api_url]
  @timezone @config[:timezone]
  @days @config[:days]

  def client do
    Tesla.client(middleware(), Application.get_env(:tesla, :adapter, Tesla.Adapter.Hackney))
  end

  def middleware do
    [
      {Tesla.Middleware.BaseUrl, @api_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Query,
       [
         daily: "temperature_2m_max",
         timezone: @timezone,
         forecast_days: @days
       ]}
    ]
  end

  @type city :: %{
          name: String.t(),
          latitude: float(),
          longitude: float()
        }

  @type weather_data :: %{
          name: String.t(),
          average_max_temp: float()
        }

  @doc """
  Fetches weather data for the specified cities and calculates the average max temperature.
  """
  @spec get_weather_forecast([city()]) :: {:ok, [weather_data()]} | {:error, String.t()}
  def get_weather_forecast(cities) do
    cities
    |> Enum.map(fn city ->
      Task.Supervisor.async_nolink(Meteo.TaskSupervisor, fn ->
        case fetch_weather_data(city) do
          {:ok, data} ->
            {:ok,
             %{
               name: city.name,
               average_max_temp: calculate_average_max_temp(data)
             }}

          error ->
            error
        end
      end)
    end)
    |> Task.await_many(:timer.seconds(10))
    |> process_results()
  end

  defp fetch_weather_data(city) do
    query = [latitude: city.latitude, longitude: city.longitude]

    case Tesla.get(client(), "", query: query) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, "API request failed with status: #{status} for #{city.name}"}

      {:error, reason} ->
        {:error, "API request failed: #{inspect(reason)} for #{city.name}"}
    end
  end

  defp calculate_average_max_temp(%{"daily" => %{"temperature_2m_max" => temps}})
       when is_list(temps) do
    temps
    |> Enum.take(@days)
    |> Enum.sum()
    |> Kernel./(@days)
    |> Float.round(1)
  end

  defp calculate_average_max_temp(_invalid_data), do: 0.0

  defp process_results(results) do
    {successes, errors} = Enum.split_with(results, &match?({:ok, _}, &1))

    case {successes, errors} do
      {successes, []} ->
        {:ok, Enum.map(successes, fn {:ok, data} -> data end)}

      {_, _} ->
        error_messages =
          errors
          |> Enum.map(fn {:error, reason} -> reason end)
          |> Enum.join(", ")

        {:error, "Some requests failed: #{error_messages}"}
    end
  end
end
