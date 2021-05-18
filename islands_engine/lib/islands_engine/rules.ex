defmodule IslandsEngine.Rules do
  alias __MODULE__

  defstruct state: :initialized, player1: :islands_not_set, player2: :islands_not_set

  def new(), do: %Rules{}

  @doc """
    :initialize, transform state from initialized to players_set
    :players_set, it's not okay for player to position islands if the player state is islands_set
  """
  def check(%Rules{state: :initialized} = rules, :add_player), do: {:ok, %Rules{rules | state: :players_set}}

  # it's not okay for player to position islands if the player state is islands_set
  def check(%Rules{state: :players_set} = rules, {:position_islands, player}) do
    case Map.fetch!(rules, player) do
      :islands_set -> :error
      :islands_not_set -> {:ok, rules}
    end
  end


  # transform state from :players_set to player1_turn if both player islands set
  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)
    case both_players_islands_set?(rules) do
      true -> {:ok, %Rules{rules | state: :player1_turn}}
      false -> {:ok, rules}
    end
  end

  # transform state from player1_turn to player2_turn
  def check(%Rules{state: :player1_turn} = rules, {:guess_coordinate, :player1}), do: {:ok, %Rules{rules | state: :player2_turn}}

  # detemine whether or not the state machine should transition to :game_over from :player2_turn
  def check(%Rules{state: :player1_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %Rules{rules | state: :game_over}}
    end
  end

  # transform state from player2_turn to player1_turn
  def check(%Rules{state: :player2_turn} = rules, {:guess_coordinate, :player2}), do: {:ok, %Rules{rules | state: :player1_turn}}

  # determine whether or not the state machine should transition to :game_over from :player2_turn
  def check(%Rules{state: :player2_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {%Rules{rules | state: :game_over}}
    end
  end

  # catchall clause: we don't transform the value of the :state key, by simply returning :error
  def check(_state, _action), do: :error

  defp both_players_islands_set?(%Rules{} = rules), do: rules.player1 == :islands_set && rules.player2 == :islands_set
end
