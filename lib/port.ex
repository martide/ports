defmodule Ports.Port do
  @moduledoc """
    Port struct.
  """

  defstruct [
    :country,
    :location,
    :name,
    :subdivision,
    :status,
    :function,
    :date,
    :iata,
    :coordinates
  ]
end
