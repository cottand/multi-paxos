defmodule AcceptorTest do
  use ExUnit.Case

  def config, do: %{ :debug_level => :DEBUG,}

  test "p1a accepts greater ballot" do
    acceptor = spawn(Acceptor, :start, [config])

    ballot1 = {1, self()}
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

    ballot1 = {10, self()}
    send acceptor, {:p1a, self(), ballot1, 0}

    receive do
      {:p1b, id, ballot, accepted} ->
        assert id == acceptor
        assert ballot == ballot1
        assert MapSet.size(accepted) == 0
      after
        1_000 -> assert false
    end

    ballot2 = {1, self()}
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

    ballot1 = {1, self()}
    send acceptor, {:p1a, self(), ballot1, 0}

    receive do
      {:p1b, id, ballot, accepted} ->
        assert id == acceptor
        assert ballot == ballot1
        assert MapSet.size(accepted) == 0
      after
        1_000 -> assert false
    end

    ballot2 = {10, self()}
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

  test "multiple scouts (TEST IS BROKEN)" do
    acceptor = spawn(Acceptor, :start, [config])

    scout1 = spawn(fn ->
      receive do {:p1b, id, ballot, accepted} ->
        assert id == acceptor
        {bid, _} = ballot
        assert bid == 1
      end
    end)

    scout2 = spawn(fn ->
      receive do {:p1b, id, ballot, accepted} ->
       assert id == acceptor
        {bid, _} = ballot
        assert bid == 1
      end
    end)

    ballot1 = {1, scout1}
    ballot2 = {1, scout2}

    send acceptor, {:p1a, scout1, ballot1, 0}
    send acceptor, {:p1a, scout2, ballot2, 0}
  end
end
