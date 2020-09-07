defmodule MnesiaPlaygroundTest do
  use ExUnit.Case
  doctest MnesiaPlayground

  test "greets the world" do
    assert MnesiaPlayground.hello() == :world
  end
end
