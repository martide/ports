defmodule Ports.Application do
  @moduledoc false

  use Application

  alias Ports.Loader

  @impl true
  def start(_type, _args) do
    :persistent_term.put({Ports, :all}, Loader.load_ports())

    Supervisor.start_link([], strategy: :one_for_one, name: Ports.Supervisor)
  end
end
