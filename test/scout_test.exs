# Nicolas D'Cotta (nd3018) and William Profit (wtp18)

defmodule ScoutTest do
  use ExUnit.Case

  def config, do: %{ :debug_level => :DEBUG,}

  test "sends p1a to all acceptors on startup" do
    ballot1 = {1, self()}
    scout = spawn(Scout, :start, [self(), MapSet.new([self()])])
  end
end
