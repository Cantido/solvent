defmodule SolventTest do
  use ExUnit.Case
  doctest Solvent

  test "greets the world" do
    assert Solvent.hello() == :world
  end
end
