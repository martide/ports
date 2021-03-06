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

  def load_code_list do
    "code-list.csv"
    |> csv_decode()
    |> Stream.map(fn [
                       _change,
                       country,
                       location,
                       name,
                       _name_wo_diacritics,
                       subdivision,
                       status,
                       function,
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
    |> Enum.to_list()
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

  defp csv_decode(file_name) do
    [:code.priv_dir(:ports), "data", file_name]
    |> Path.join()
    |> File.stream!([], :line)
    |> CSVParser.parse_stream(skip_headers: false)
  end
end
