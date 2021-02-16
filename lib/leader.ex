defmodule Leader do
  def start(config) do
    receive do
      {:BIND, acceptors, replicas} ->
        ballot = {0, config.node_num, self()}
        spawn(Scout, :start, [self(), acceptors, ballot, config])
        active = false
        send(config.monitor, {:LEADER_ACTIVE, active, config.node_num})
        proposals = Map.new()
        next(acceptors, replicas, ballot, proposals, active, config)
    end
  end

  defp next(acceptors, replicas, ballot, proposals, active, config) do
    receive do
      # If a fellow leader pings us, we reply systematically
      {:ping, other_leader} ->
        send(other_leader, {:pong})
        next(acceptors, replicas, ballot, proposals, active, config)

      {:propose, slot, command} ->
        new_proposal = not Map.has_key?(proposals, slot)
        age = if new_proposal, do: "new", else: "old"
        Util.log(config, :DEBUG, "active: #{active}, received #{age} proposal for slot #{slot}")
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
        Util.log(config, :DEBUG, "active: #{active}, received ADOPTED")
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

      {:preempted, other_ballot} ->
        {other_ballot_num, _other_leader_node_num, other_leader} = other_ballot

        Util.log(
          config,
          :DEBUG,
          "leader: with #{inspect(ballot)} preempted with #{inspect(other_ballot)}"
        )

        {active, ballot} =
          if Util.ballot_greater?(other_ballot, ballot) do
            Util.log(config, :WARN, "Preempted by #{inspect({active, ballot})}")

            # TODO: this here means leader got preempted - spawning a new scout and just increasing
            # ballot numper will lead to a livelock between 2 leaders (they each keep increasing the ballot number)
            # so we have to do something to ensure _liveness_ - paper suggests just pinging the
            # other leader but I am not sure how that helps.
            pinging(other_leader)
            new_ballot = {other_ballot_num + 1, config.node_num, self()}
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

  defp pinging(other_leader) do
    send(other_leader, {:ping, self()})

    receive do
      {:pong} ->
        pinging(other_leader)
    after
      1_000 -> nil
    end
  end
end
