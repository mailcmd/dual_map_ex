defmodule DualMapTest do
  use ExUnit.Case

  test "Create new empty DualMap" do
    assert DualMap.new() |> DualMap.to_list() == []
  end

end
