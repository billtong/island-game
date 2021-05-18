defmodule CoordinateTest do
  use ExUnit.Case

  alias IslandsEngine.Coordinate

  test "create a valid coordinate" do
    assert {:ok, %Coordinate{col: 1, row: 1}} = Coordinate.new(1, 1)
  end

  test "create an invalid coordinate" do
    assert {:error, :invalid_coordinate} = Coordinate.new(1, -1)
  end

end
