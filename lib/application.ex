defmodule Meteo.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Meteo.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Meteo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
