defmodule IslandsEngine.Game do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias IslandsEngine.{Board, Coordinate, Guesses, Island, Rules}

  @players [:player1, :player2]
  @timeout 60 * 60 * 1 * 1000 # 1hours

  @doc """
  name each process in Game.start_link/1, key is {Registry.Game, name}
  """
  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  @doc """
  name is the player1's name
  """
  def start_link(name) when is_binary(name), do: GenServer.start_link(__MODULE__, name, name: via_tuple(name))

  @doc """
  add first player's name, initialize state
  """
  def init(name) do
    send(self(), {:set_state, name})
    {:ok, fresh_state(name)}
  end

  @doc """
  trigger by send/2 in init/1,
  check the :game_state table for any state stored under the first player's name
  """
  def handle_info({:set_state, name}, _state) do
    state = case :ets.lookup(:game_state, name) do
      [] -> fresh_state(name)
      [{_key, state}] -> state
    end
    :ets.insert(:game_state, {name, state})
    {:noreply, state, @timeout}
  end

  @doc """
  when a genserver process time out, it will receive a :timeout message
  this function handles that message and return a :stop tuple
  """
  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  @doc """
  :stop tuple trigger this function to clean up :game_state table data
  """
  def terminate({:shutdown, :timeout}, state) do
    :ets.delete(:game_state, state.player1.name)
    :ok
  end

  def terminate(_reason, _state), do: :ok

  def add_player(game, name) when is_binary(name), do: GenServer.call(game, {:add_player, name})

  @doc """
    add second user, update rules state
  """
  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player)
    do
      state
      |> update_player2_name(name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> reply_error(state, :error)
    end
  end

  @doc """
    handle messages of key for island type, row and column number for the upper-left coordinate sent by front-end
  """
  def position_island(game, player, key, row, col) when player in @players, do: GenServer.call(game, {:position_island, player, key, row, col})

  def handle_call({:position_island, player, key, row, col}, _from, state) do
    board = player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:position_islands, player}),
      {:ok, coordinate} <- Coordinate.new(row, col),
      {:ok, island} <- Island.new(key, coordinate),
      %{} = board <- Board.position_island(board, key, island)
    do
      state
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> reply_error(state, :error)
      {:error, :invalid_coordinate} -> reply_error(state, {:error, :invalid_coordinate})
      {:error, :invalid_island_type} -> reply_error(state, {:error, :invalid_island_type})
      {:error, :overlapping_island} -> reply_error(state, {:error, :overlapping_island})
    end
  end

  @doc """
  set the player's island set, and return player's board
  """
  def set_islands(game, player) when player in @players, do: GenServer.call(game, {:set_islands, player})

  def handle_call({:set_islands, player}, _from, state) do
    board = player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
      true <- Board.all_island_positioned?(board)
    do
      state
      |> update_rules(rules)
      |> reply_success({:ok, board})
    else
      :error -> reply_error(state, :error)
      false -> reply_error(state, {:error, :not_all_islands_positioned})
    end
  end

  def guess_coordinate(game, player, row, col) when player in @players, do: GenServer.call(game, {:guess_coordinate, player, row, col})

  def handle_call({:guess_coordinate, player, row, col}, _from, state) do
    opponent = opponent(player)
    opponent_board = player_board(state, opponent)

    with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player}),
      {:ok, coordinate} <- Coordinate.new(row, col),
      {hit_or_miss, forested_island, win_status, opponent_board} <- Board.guess(opponent_board, coordinate),
      {:ok, rules} <- Rules.check(rules, {:win_check, win_status})
    do
      state
      |> update_board(opponent, opponent_board)
      |> update_guesses(player, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> reply_success({hit_or_miss, forested_island, win_status})
    else
      :error -> reply_error(state, :error)
      {:error, :invalid_coordinate} -> reply_error(state, {:error, :invalid_coordinate})
    end
  end


  #update player's name in the state data
  defp update_player2_name(state, name), do: put_in(state.player2.name, name)

  #set the transformed rules struct back in the state data
  defp update_rules(state, rules), do: %{state | rules: rules}

  #update the player's board
  defp update_board(state, player, board), do: Map.update!(state, player, fn player -> %{player | board: board} end)

  #update the player's guesses
  defp update_guesses(state, player, hit_or_miss, coordinate) do
    update_in(state[player].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end

  # transform into standard handle_call return tuples, update ets table
  defp reply_success(state, reply) do
    :ets.insert(:game_state, {state.player1.name, state})
    {:reply, reply, state, @timeout}
  end

  #transform into staand handle_call return tuples
  defp reply_error(state, reply), do: {:reply, reply, state, @timeout}

  # extracting board MapSet from player
  defp player_board(state, player), do: Map.get(state, player).board

  #get the key of player's opponent
  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1

  defp fresh_state(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    %{player1: player1, player2: player2, rules: Rules.new()}
  end

end
