defmodule Ports do
  @moduledoc """
  Module for providing ports related functions.
  """

  alias Ports.Loader

  # Load during compilation
  @ports Loader.load_code_list()
  @countries Loader.load_countries()
  @function_classifiers Loader.load_functions()
  @statuses Loader.load_statuses()
  @subdivisions Loader.load_subdivisions()

  @doc """
  Returns all ports.
  """
  def all, do: @ports

  @doc """
  Returns all countries.
  """
  def countries, do: @countries

  @doc """
  Returns one country given is alpha2 country code.

  ## Examples

      iex> %Ports.Country{name: name} = Ports.get_country("PH")
      iex> name
      "Philippines"

  """
  def get_country(country_code) do
    countries()
    |> Enum.find(&(&1.code == country_code))
  end

  @doc """
  Returns all functions.
  """
  def functions, do: @function_classifiers

  @doc """
  Returns one function given is function code.

  ## Examples

      iex> %Ports.Function{description: description} = Ports.get_function(4)
      iex> description
      "Airport"

  """
  def get_function(function_code) do
    functions()
    |> Enum.find(&(String.to_integer(&1.code) == function_code))
  end

  @doc """
  Returns all statuses.
  """
  def statuses, do: @statuses

  @doc """
  Returns one status given is status code.

  ## Examples

      iex> %Ports.Status{description: description} = Ports.get_status("AA")
      iex> description
      "Approved by competent national government agency"

  """
  def get_status(status_code) do
    statuses()
    |> Enum.find(&(&1.code == status_code))
  end

  @doc """
  Returns all subdivisions.
  """
  def subdivisions, do: @subdivisions

  @doc """
  Returns one subdivision given is subdivision country and code.

  ## Examples

      iex> %Ports.Subdivision{name: name} = Ports.get_subdivision("PH", "00")
      iex> name
      "National Capital Region (Manila)"

  """
  def get_subdivision(country_code, subdivision_code) do
    subdivisions()
    |> Enum.find(&(&1.country == country_code and &1.code == subdivision_code))
  end
end
