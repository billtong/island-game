defmodule IslandsEngine.Coordinate do
  alias __MODULE__

  @enforce_keys [:row, :col]
  defstruct [:row, :col]

  @board_range 1..10

  @doc """
  create the coordinate

  ## Examples

      iex> alias IslandsEngine.Coordinate
      iex> Coordinate.new(1, 1)
      {:ok, %IslandsEngine.Coordinate{col: 1, row: 1}}

  """
  def new(row, col) when row in (@board_range) and col in (@board_range), do: {:ok, %Coordinate{row: row, col: col}}


  @doc """
  handle error coordinate

  ## Examples

      iex> alias IslandsEngine.Coordinate
      iex> Coordinate.new(1, -1)
      {:error, :invalid_coordinate}

  """
  def new(_row, _col), do: {:error, :invalid_coordinate}

end
