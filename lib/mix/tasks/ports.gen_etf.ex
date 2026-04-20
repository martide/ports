defmodule Mix.Tasks.Ports.GenEtf do
  @shortdoc "Generates the pre-parsed ports ETF file from source CSVs"

  @moduledoc """
  Parses the UN/LOCODE CSV files via `Ports.Loader` and writes the
  resulting list of `Ports.Port` structs to `priv/data/ports.etf` as
  a compressed Erlang term.

  Run this after updating any of the UN/LOCODE CSVs in `priv/data/`:

      mix ports.gen_etf
  """

  use Mix.Task

  alias Ports.Loader

  @output_path "priv/data/ports.etf"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")

    ports = Loader.load_code_list()
    binary = :erlang.term_to_binary(ports, [:compressed])

    File.write!(@output_path, binary)

    Mix.shell().info("Wrote #{length(ports)} ports to #{@output_path}")
  end
end
