defmodule Acceptor do
  @spec start(Util.ballot(), MapSet.t({Util.ballot(), integer(), any()})) :: nil
  def start(ballot, accepted) do
    receive do
      {:p1a, leader, new_ballot} ->
        ballot = if Util.ballot_greater?(new_ballot, ballot), do: new_ballot, else: ballot
        send(leader, {:p1b, self(), ballot, accepted})
        start(ballot, accepted)

      {:p2a, leader, {new_ballot, slot, command}} ->
        accepted =
          if new_ballot == ballot,
            do: MapSet.put(accepted, {ballot, slot, command}),
            else: accepted

        send(leader, {:p2b, self(), ballot})
        start(ballot, accepted)
    end
  end
end
