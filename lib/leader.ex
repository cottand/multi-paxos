# Nicolas D'Cotta (nd3018) and William Profit (wtp18)

defmodule Leader do
  def start(config) do
    receive do
      {:BIND, acceptors, replicas} ->
        ballot = {0, config.node_num, self()}
        spawn(Scout, :start, [self(), acceptors, ballot, config])
        active = false
        send(config.monitor, {:LEADER_ACTIVE, active, config.node_num})
        proposals = Map.new()
        next(acceptors, replicas, ballot, proposals, active, config, -1)
    end
  end

  defp pinging(other_leader, ballot, try_count, time_left) do
    if try_count < 16 and time_left > 0  do
      timeout = (:math.pow(2, try_count) |> round) * 100

      :timer.sleep(timeout)
      send(other_leader, {:ping, self()})

      receive do
        {:pong} ->
          pinging(other_leader, ballot, try_count + 1, time_left - timeout)
      after
        timeout -> nil
      end
    end
  end

  defp next(acceptors, replicas, ballot, proposals, active, config, latest_preempted_ballot_num) do
    receive do
      # If a fellow leader pings us, we reply systematically
      {:ping, other_leader} ->
        send(other_leader, {:pong})
        next(acceptors, replicas, ballot, proposals, active, config, latest_preempted_ballot_num)

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

        next(acceptors, replicas, ballot, proposals, active, config, latest_preempted_ballot_num)

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
        next(acceptors, replicas, ballot, proposals, active, config, latest_preempted_ballot_num)

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
            Util.log(config, :DEBUG, "Preempted by #{inspect({active, ballot})}")

            # back off for a period of time t, where t is longer if the ballot number is big
            if config.prevent_livelock, do: pinging(other_leader, other_ballot, 0, other_ballot_num * 20)

            new_ballot = {other_ballot_num + 1, config.node_num, self()}
            spawn(Scout, :start, [self(), acceptors, new_ballot, config])

            {false, new_ballot}
          else
            {active, ballot}
          end

        send(config.monitor, {:LEADER_ACTIVE, active, config.node_num})
        next(acceptors, replicas, ballot, proposals, active, config, latest_preempted_ballot_num)

      unexpected ->
        Util.halt("Leader received unexpected #{inspect(unexpected)}")
    end
  end
end
