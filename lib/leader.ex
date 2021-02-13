defmodule Leader do
  def start(config) do
    receive do
      {:BIND, acceptors, replicas} ->
        ballot = {0, self()}
        spawn(Scout, :start, [self(), acceptors, ballot, config])
        active = false
        send(config.monitor, {:LEADER_ACTIVE, active, config.node_num})
        proposals = Map.new()
        next(acceptors, replicas, ballot, proposals, active, config)
    end
  end

  defp next(acceptors, replicas, ballot, proposals, active, config) do
    receive do
      {:propose, slot, command} ->
        new_proposal = !Map.has_key?(proposals, slot)
        proposals = if new_proposal, do: Map.put(proposals, slot, command), else: proposals

        if new_proposal do
          if active,
            do:
              spawn(Commander, :start, [
                self(),
                acceptors,
                replicas,
                {ballot, slot, command},
                config
              ])
        end

        next(acceptors, replicas, ballot, proposals, active, config)

      # pvals :: MapSet.t({ballot, slot, command})
      {:adopted, ^ballot, pvals} ->
        proposals = Util.update_with(proposals, Util.pmax(pvals, config))

        for {slot, command} <- proposals,
            do:
              spawn(Commander, :start, [
                self(),
                acceptors,
                replicas,
                {ballot, slot, command},
                config
              ])

        active = true
        send(config.monitor, {:LEADER_ACTIVE, active, config.node_num})
        next(acceptors, replicas, ballot, proposals, active, config)

      {:adopted, other_ballot, _} ->
        Util.halt(
          "#{inspect(self())} - ERROR: Received unexpected ballot #{inspect(other_ballot)}"
        )

      {:preempted, {other_ballot_num, other_leader}} ->
        {active, ballot} =
          if Util.ballot_greater?({other_ballot_num, other_leader}, ballot) do
            new_ballot = {other_ballot_num + 1, self()}
            spawn(Scout, :start, [self(), acceptors, new_ballot, config])

            {false, new_ballot}
          else
            {active, ballot}
          end

        send(config.monitor, {:LEADER_ACTIVE, active, config.node_num})
        next(acceptors, replicas, ballot, proposals, active, config)

      unexpected ->
        Util.halt("Leader received unexpected #{inspect(unexpected)}")
    end
  end
end
