defmodule Mix.Tasks.Ports.GenEtf do
  @shortdoc "Generates the pre-parsed ports ETF file from source CSVs"

  @moduledoc """
  Parses the UN/LOCODE CSV files via `Ports.Loader` and writes the
  resulting list of `Ports.Port` structs to `priv/data/ports.etf` as
  a compressed Erlang term.

  Run this after updating any of the UN/LOCODE CSVs in `priv/data/`:

      mix ports.gen_etf

  Pass `--check` to verify the committed ETF matches the current CSV
  contents without writing. Used in CI to catch stale ETF files.
  """

  use Mix.Task

  alias Ports.Loader

  @output_path "priv/data/ports.etf"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [check: :boolean])

    Mix.Task.run("compile")

    ports = Loader.load_code_list()

    if opts[:check] do
      check(ports)
    else
      write(ports)
    end
  end

  defp write(ports) do
    binary = :erlang.term_to_binary(ports, [:compressed])
    File.write!(@output_path, binary)
    Mix.shell().info("Wrote #{length(ports)} ports to #{@output_path}")
  end

  defp check(ports) do
    existing =
      @output_path
      |> File.read!()
      |> :erlang.binary_to_term()

    if existing == ports do
      Mix.shell().info("#{@output_path} is up to date (#{length(ports)} ports)")
    else
      Mix.raise("""
      #{@output_path} is out of date with the source CSVs.
      Run `mix ports.gen_etf` and commit the result.
      """)
    end
  end
end
