defmodule Ports.Loader do
  @moduledoc false

  alias Ports.{
    Country,
    Function,
    Port,
    Status,
    Subdivision
  }

  NimbleCSV.define(CSVParser, separator: ",", escape: "\"")

  for path <- Path.wildcard("priv/data/*.csv") do
    @external_resource path
  end

  defguard is_empty(data) when data in [nil, ""]

  @code_list_sources [
    "2023-2 UNLOCODE CodeListPart1.csv",
    "2023-2 UNLOCODE CodeListPart2.csv",
    "2023-2 UNLOCODE CodeListPart3.csv"
  ]

  def load_code_list do
    @code_list_sources
    |> csv_decode()
    |> Stream.map(fn [
                       _change,
                       country,
                       location,
                       name,
                       _name_wo_diacritics,
                       subdivision,
                       function,
                       status,
                       date,
                       iata,
                       coordinates,
                       _remarks
                     ] ->
      %Port{
        country: country,
        location: location,
        name: name,
        subdivision: subdivision,
        status: status,
        function: function,
        date: date,
        iata: iata,
        coordinates: coordinates
      }
    end)
    |> Stream.reject(fn
      %{country: country, location: location} when is_empty(country) or is_empty(location) -> true
      _ -> false
    end)
    |> Stream.map(fn port -> Map.update!(port, :name, &to_valid_string/1) end)
    |> Enum.to_list()
  end

  defp to_valid_string(string) do
    string |> :binary.bin_to_list() |> :unicode.characters_to_binary()
  end

  def load_countries do
    "country-codes.csv"
    |> csv_decode()
    |> Stream.map(fn [
                       country_code,
                       country_name
                     ] ->
      %Country{
        code: country_code,
        name: country_name
      }
    end)
    |> Enum.to_list()
  end

  def load_functions do
    "function-classifiers.csv"
    |> csv_decode()
    |> Stream.map(fn [
                       function_code,
                       function_description
                     ] ->
      %Function{
        code: function_code,
        description: function_description
      }
    end)
    |> Enum.to_list()
  end

  def load_statuses do
    "status-indicators.csv"
    |> csv_decode()
    |> Stream.map(fn [
                       status_code,
                       status_description
                     ] ->
      %Status{
        code: status_code,
        description: status_description
      }
    end)
    |> Enum.to_list()
  end

  def load_subdivisions do
    "subdivision-codes.csv"
    |> csv_decode()
    |> Stream.map(fn [
                       status_country,
                       status_code,
                       status_name
                     ] ->
      %Subdivision{
        country: status_country,
        code: status_code,
        name: status_name
      }
    end)
    |> Enum.to_list()
  end

  defp csv_decode(file_names) do
    file_names = List.wrap(file_names)

    streams =
      Enum.map(file_names, fn file_name ->
        [:code.priv_dir(:ports), "data", file_name]
        |> Path.join()
        |> File.stream!()
      end)

    streams
    |> Stream.concat()
    |> CSVParser.parse_stream(skip_headers: false)
  end
end
