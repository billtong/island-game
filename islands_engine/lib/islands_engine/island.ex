defmodule IslandsEngine.Island do
  @moduledoc """
  island has a role to play in three actions: positioning islands, guessing coordinates, and checking for a forsted island
  """
  alias IslandsEngine.{Coordinate, Island}

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [:coordinates, :hit_coordinates]

  @doc """
  create the island

  ## Examples

      iex> alias IslandsEngine.{Coordinate, Island}
      iex> {:ok, c1} = Coordinate.new(3, 4)
      iex> {:ok, c2} = Coordinate.new(10, 10)
      iex> {:ok, %Island{coordinates: coordinates}} = Island.new(:atoll, c1)
      iex> coordinates
      #MapSet<[%IslandsEngine.Coordinate{col: 4, row: 3}, %IslandsEngine.Coordinate{col: 4, row: 5}, %IslandsEngine.Coordinate{col: 5, row: 3}, %IslandsEngine.Coordinate{col: 5, row: 4}, %IslandsEngine.Coordinate{col: 5, row: 5}]>
      iex> Island.new(:wrong, c1)
      {:error, :invalid_island_type}
      iex> Island.new(:square, c2)
      {:error, :invalid_coordinate}
  """
  def new(type, %Coordinate{} = upper_left) do
    with [_|_] = offsets <- offsets(type),  # pattern match [_|_] check list offsets empty
    %MapSet{} = coordinates <- add_coordinates(offsets, upper_left)
    do
      {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  defp offsets(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]

  defp offsets(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]

  defp offsets(:dot), do: [{0, 0}]

  defp offsets(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]

  defp offsets(:s_shape), do: [{0, 0}, {0, 2}, {1, 0}, {1, 1}]

  defp offsets(_), do: {:error, :invalid_island_type}

  # check every coordinate validation
  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
      add_coordinates(acc, upper_left, offset)
    end)
  end

  defp add_coordinates(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coordinate} -> {:cont, MapSet.put(coordinates, coordinate)}
      {:error, :invalid_coordinate} -> {:halt, {:error, :invalid_coordinate}}
    end
  end

  @doc """
  check for overlaps when positioning islands
  """
  def overlaps?(existing_island, new_island), do: not MapSet.disjoint?(existing_island.coordinates, new_island.coordinates)

  @doc """
  the board will use this function as it tests all islands for a guessed coordinate
  if a guessed coordinate is a member of the coordinate set,
  we need to transform the island by adding the coordinate to the hist coordinates set,
  and return a tuple containing :hit and the transformed island
  if it isn't, return miss
  """
  def guess(%Island{} = island, %Coordinate{} = coordinate) do
    case MapSet.member?(island.coordinates, coordinate) do
      true ->
        hit_coordinates = MapSet.put(island.hit_coordinates, coordinate)
        {:hit, %{island | hit_coordinates: hit_coordinates}}
      false -> :miss
    end
  end

  @doc """
  check wether an island is forested
  """
  def forested?(%Island{} = island), do: MapSet.equal?(island.coordinates, island.hit_coordinates)

  def types(), do: [:atoll, :dot, :l_shape, :s_shape, :square]

end
