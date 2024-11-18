defmodule ZerokitTest do
  use ExUnit.Case
  doctest Zerokit

  test "greets the world" do
    assert Zerokit.hello() == :world
  end
end
