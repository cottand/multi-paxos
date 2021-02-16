# Nicolas D'Cotta (nd3018) and William Profit (wtp18)

defmodule AcceptorTest do
  use ExUnit.Case

  def config, do: %{ :debug_level => :DEBUG,}

  test "p1a accepts greater ballot" do
    acceptor = spawn(Acceptor, :start, [config])

    ballot1 = {1, 1, self()}
    send acceptor, {:p1a, self(), ballot1, 0}

    receive do
      {:p1b, id, ballot, accepted} ->
        assert id == acceptor
        assert ballot == ballot1
        assert MapSet.size(accepted) == 0
      after
        1_000 -> assert false
    end
  end

  test "p1a discards second smaller ballot" do
    acceptor = spawn(Acceptor, :start, [config])

    ballot1 = {10, 1, self()}
    send acceptor, {:p1a, self(), ballot1, 0}

    receive do
      {:p1b, id, ballot, accepted} ->
        assert id == acceptor
        assert ballot == ballot1
        assert MapSet.size(accepted) == 0
      after
        1_000 -> assert false
    end

    ballot2 = {1, 1, self()}
    send acceptor, {:p1a, self(), ballot2, 0}

    receive do
      {:p1b, id, ballot, accepted} ->
        assert id == acceptor
        assert ballot == ballot1
        assert MapSet.size(accepted) == 0
      after
        1_000 -> assert false
    end
  end

  test "p1a accepts second greater ballot" do
    acceptor = spawn(Acceptor, :start, [config])

    ballot1 = {1, 1,self()}
    send acceptor, {:p1a, self(), ballot1, 0}

    receive do
      {:p1b, id, ballot, accepted} ->
        assert id == acceptor
        assert ballot == ballot1
        assert MapSet.size(accepted) == 0
      after
        1_000 -> assert false
    end

    ballot2 = {10, 1, self()}
    send acceptor, {:p1a, self(), ballot2, 0}

    receive do
      {:p1b, id, ballot, accepted} ->
        assert id == acceptor
        assert ballot == ballot2
        assert MapSet.size(accepted) == 0
      after
        1_000 -> assert false
    end
  end
end
