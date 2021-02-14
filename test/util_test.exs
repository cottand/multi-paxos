defmodule UtilTest do
  use ExUnit.Case
  import Util

  test "bottom is always smaller" do
    b1 = {0, spawn(fn -> nil end)}
    assert Util.ballot_greater?(b1, :bottom)
    assert not Util.ballot_greater?(:bottom, b1)
  end

  test "bottom is smaller as num" do
    b1 = {0, spawn(fn -> nil end)}
    assert Util.ballot_as_num(b1) > Util.ballot_as_num(:bottom)
  end


  test "ballots from same PID with different nums are compared properly" do
    pid = spawn(fn -> nil end)
    b1 = {0, pid}
    b2 = {1, pid}
    assert Util.ballot_greater?(b2, b1)
    assert Util.ballot_as_num(b2) > Util.ballot_as_num(b1)
  end


  test "ballots from diff PID with different nums are compared properly" do
    b1 = {0, spawn(fn -> nil end)}
    b2 = {1, spawn(fn -> nil end)}
    assert Util.ballot_greater?(b2, b1)
    assert ballot_as_num(b2) > ballot_as_num(b1)
  end

  test "ballots from diff PID with same number are _not_ equal" do
    pid1 = spawn(fn -> nil end)
    pid2 = spawn(fn -> nil end)
    assert pid1 != pid2
    b1 = {1, pid1}
    b2 = {1, pid2}
    assert not (b1 == b2)
    assert ballot_as_num(b2) != ballot_as_num(b1)
  end

  defp comapre_numerical(b1, b2), do: ballot_as_num(b1) > ballot_as_num(b2)

  test "ballots from diff PID with same number can be compared consistently" do
    pid1 = spawn(fn -> nil end)
    pid2 = spawn(fn -> nil end)
    assert comapre_numerical({0, pid1},{0, pid2}) == ballot_greater?({0, pid1},{0, pid2})
    assert comapre_numerical({0, pid2},{0, pid1}) == ballot_greater?({0, pid2},{0, pid1})
    b1 = ballot_as_num {0, pid1}
    b2 = ballot_as_num {0, pid2}
    greater = b1 > b2
    if greater do
      assert not (b2 > b1)
    else
      assert b2 >= b1
    end
  end
end
