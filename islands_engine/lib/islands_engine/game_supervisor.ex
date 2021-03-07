defmodule IslandsEngine.GameSupervisor do
  use DynamicSupervisor

  alias IslandsEngine.Game

  @doc """
  start a new GameSupervisor prcess
  """
  def start_link(_options), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  @doc """
  __MODULE__ here evaluates to GameSupervisor, will translate into the supervisor PID
  GameSupervisor looks up the child_spec for the Game module, and passes in the argument supplied to start and supervise the game
  """
  def start_game(name) do
    spec = %{id: Game, start: {Game, :start_link, [name]}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc """
  clean up data in :game_state table,
  terminate the game process
  """
  def stop_game(name) do
    :ets.delete(:game_state, name)
    DynamicSupervisor.terminate_child(__MODULE__, pid_from_name(name))
  end

  #find the actual PID of game via player's name
  defp pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end

end
