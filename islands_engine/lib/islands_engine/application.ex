defmodule IslandsEngine.Application do
  use Application

  @doc """
  top-level supervisor process called IslandsEngine.Supervisor
  """
  def start(_type, _args) do
    children = [
      #start the Registry, and specify that keys should be unique for the Registry.Game module
      {Registry, keys: :unique, name: Registry.Game},
      #for starting and supervising each new game
      IslandsEngine.GameSupervisor
    ]

    # game state table avaliable at runtime
    :ets.new(:game_state, [:public, :named_table])

    opts = [strategy: :one_for_one, name: IslandsEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
