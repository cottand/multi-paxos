defmodule Acceptor do
  def start(config) do
    ballot = :bottom
    accepted = MapSet.new()
    next(config, ballot, accepted)
  end

  def next(config, ballot, accepted) do
    receive do
      {:p1a, leader_scout, new_ballot} ->
        Util.log config, :DEBUG, "Comparing #{inspect new_ballot} > #{inspect ballot}"
        ballot = if Util.ballot_greater?(new_ballot, ballot), do: new_ballot, else: ballot
        send(leader_scout, {:p1b, self(), ballot, accepted})
        next(config, ballot, accepted)

      {:p2a, leader, {new_ballot, slot, command}} ->
        Util.log config, :DEBUG, "Acceptor received p2a for slot #{slot}"
        accepted =
          if new_ballot == ballot,
            do: MapSet.put(accepted, {ballot, slot, command}),
            else: accepted

        send(leader, {:p2b, self(), ballot})
        next(config, ballot, accepted)
    end
  end
end
