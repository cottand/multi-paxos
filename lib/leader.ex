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
        next(acceptors, replicas, ballot, proposals, active, config, 25)
    end
  end

  defp wait(other_leader, waiting_period_ms, other_ballot_num) do
    time_left = other_ballot_num * waiting_period_ms
    wait_helper(other_leader, time_left)
    waiting_period_ms * 0.9
  end

  # returns after waiting_time_left, or when we think the other leader might have crashed
  defp wait_helper(other_leader, time_left) do
    timeout = 100
    if time_left > 0 do
      send(other_leader, {:ping, self()})
      :timer.sleep(timeout)
      receive do
        {:pong} ->
          wait_helper(other_leader, time_left - timeout)
      after
        timeout -> nil
      end
    end

  end

  defp next(acceptors, replicas, ballot, proposals, active, config, waiting_period_ms) do
    Util.log(config, :WARN, "Current waiting time: #{waiting_period_ms}")
    receive do
      # If a fellow leader pings us, we reply systematically
      {:ping, other_leader} ->
        send(other_leader, {:pong})
        next(acceptors, replicas, ballot, proposals, active, config, waiting_period_ms)

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

        next(acceptors, replicas, ballot, proposals, active, config, waiting_period_ms)

      # pvals :: MapSet.t({ballot, slot, command})
      {:adopted, ^ballot, pvals} ->
        Util.log(config, :DEBUG, "active: #{active}, received ADOPTED")
        waiting_period_ms =
          if config.prevent_livelock, do: waiting_period_ms + 10, else: waiting_period_ms

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
        next(acceptors, replicas, ballot, proposals, active, config, waiting_period_ms)

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

        {active, ballot, waiting_period_ms} =
          if Util.ballot_greater?(other_ballot, ballot) do
            Util.log(config, :DEBUG, "Preempted by #{inspect({active, ballot})}")

            # back off for a period of time t, where t is longer if the ballot number is big
            waiting_period_ms =
              if config.prevent_livelock,
                do: wait(other_leader, waiting_period_ms, other_ballot_num),
                else: waiting_period_ms

            new_ballot = {other_ballot_num + 1, config.node_num, self()}
            spawn(Scout, :start, [self(), acceptors, new_ballot, config])

            {false, new_ballot, waiting_period_ms}
          else
            {active, ballot, waiting_period_ms}
          end

        send(config.monitor, {:LEADER_ACTIVE, active, config.node_num})
        next(acceptors, replicas, ballot, proposals, active, config, waiting_period_ms)

      {:pong} ->
        # some leader replied to us with a pong from when we were pinging them
        nil
      unexpected ->
        Util.halt("Leader received unexpected #{inspect(unexpected)}")
    end
  end
end
