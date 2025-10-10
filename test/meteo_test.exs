defmodule MeteoTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @success_response %{
    "daily" => %{
      "temperature_2m_max" => [25.0, 26.0, 47.0, 28.0, 29.0, 30.0, 31.0],
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

  describe "get_forecast/0" do
    test "returns sorted list of cities with average temperatures" do
      Tesla.Mock.mock(fn %{query: query} ->
        assert query[:latitude] in [-23.55, -19.92, -25.43]
        assert query[:longitude] in [-46.63, -43.94, -49.27]
        assert query[:daily] == "temperature_2m_max"
        assert query[:timezone] == "America/Sao_Paulo"

        {:ok, %Tesla.Env{status: 200, body: @success_response}}
      end)

      assert {:ok, results} = Meteo.get_forecast()
      assert length(results) == 3

      assert [first, second, third] = results
      assert first.average_max_temp >= second.average_max_temp
      assert second.average_max_temp >= third.average_max_temp
    end
  end

  describe "print_forecast/0" do
    test "prints formatted forecast to stdout" do
      Tesla.Mock.mock(fn %{query: _query} ->
        {:ok, %Tesla.Env{status: 200, body: @success_response}}
      end)

      output =
        capture_io(fn ->
          assert :ok = Meteo.print_forecast()
        end)
        |> String.trim()
        |> String.split("\n")

      assert output == [
               "São Paulo: 30.8°C",
               "Belo Horizonte: 30.8°C",
               "Curitiba: 30.8°C"
             ]
    end

    test "handles errors gracefully" do
      Tesla.Mock.mock(fn _ ->
        {:error, :timeout}
      end)

      output =
        capture_io(fn ->
          assert :error = Meteo.print_forecast()
        end)

      assert output ==
               "Error fetching weather data: Some requests failed: API request failed: :timeout for São Paulo, API request failed: :timeout for Belo Horizonte, API request failed: :timeout for Curitiba\n"
    end
  end
end
