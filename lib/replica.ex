defmodule Replica do
  @type replica_state :: %{
          :database => pid(),
          :slot_in => integer(),
          :slot_out => integer(),
          :requests => MapSet.t(any()),
          :proposals => Util.proposal_set(),
          :decisions => MapSet.t({integer(), Util.command()}),
          :window => integer(),
          :leaders => MapSet.t(pid())
        }

  def start(config, database) do
    receive do
      {:BIND, leaders} ->
        replica_state = %{
          :database => database,
          :slot_in => 1,
          :slot_out => 1,
          :requests => MapSet.new(),
          :proposals => Map.new(),
          :decisions => MapSet.new(),
          :window => 10,
          :leaders => leaders
        }

        next(replica_state)
    end
  end

  @spec propose(replica_state) :: replica_state()
  defp propose(state) do
    # FIXME do we do reconfig options?
    slot_in = state.slot_in
    cmd = Enum.find(state.requests, nil, fn _ -> true end)

    if slot_in < state.slot_out + state.window && cmd != nil do
      has_slot_in = Enum.find(state.decisions, nil, fn {slot_num, _} -> slot_num == slot_in end)

      {requests, proposals} =
        if has_slot_in == nil do
          for leader <- state.leaders, do: send(leader, {:propose, slot_in, cmd})
          {MapSet.delete(state.requests, cmd), Map.put(state.proposals, slot_in, cmd)}
        else
          {state.requests, state.proposals}
        end

      slot_in = slot_in + 1
      propose(%{state | requests: requests, proposals: proposals, slot_in: slot_in})
    else
      state
    end
  end

  defp perform(state, command) do
    {client, command_id, op} = command

    state =
      if Enum.any?(state.decisions, fn {s, c} -> s < state.slot_out and c == command end) do
        %{state | slot_out: state.slot_out + 1}
      else
        # Execute op
        send(state.database, {:EXECUTE, op})
        # Answer client
        send(client, {:response, command_id, "lol"})

        %{state | slot_out: state.slot_out + 1}
      end

    state
  end

  # @spec next(replica_state()) :
  defp next(state) do
    state =
      receive do
        {:request, command} ->
          %{state | requests: MapSet.put(state.requests, command)}

        {:decision, slot, command} ->
          # state = %{state | decisions: MapSet.put(state.decisions, {slot, command})}
          decisions = MapSet.put(state.decisions, {slot, command})
          next_helper(%{state | decisions: decisions})

        other ->
          IO.puts("#{inspect(self())} (replica): Unexpected command received: #{inspect(other)}")
          state
      end

    state = propose(state)
    next(state)
  end

  @spec next_helper(replica_state) :: replica_state
  defp next_helper(state) do
    slot_out = state.slot_out
    proposals = state.proposals
    requests = state.requests

    {decided_cmd, _} =
      Enum.find(state.decisions, {nil, nil}, fn {slot_num, _} -> slot_num == slot_out end)

    if decided_cmd != nil do
      # {proposed_cmd, _} = Enum.find(state.proposals, {nil, nil}, fn {slot_num, _} -> slot_num == slot_out end)
      {proposals, requests} =
        if Map.has_key?(proposals, slot_out) do
          proposed_cmd = Map.get(proposals, slot_out)
          new_proposals = Map.delete(proposals, slot_out)

          new_requests =
            if proposed_cmd != decided_cmd, do: MapSet.put(requests, proposed_cmd), else: requests

          {new_proposals, new_requests}
        else
          {proposals, requests}
        end

      state = perform(%{state | proposals: proposals, requests: requests}, decided_cmd)
      next_helper(state)
    else
      state
    end
  end
end
