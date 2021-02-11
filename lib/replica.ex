defmodule Replica do
  def start(leaders, initial_state) do
    next(initial_state, 1, 1, MapSet.new(), MapSet.new(), MapSet.new())
  end

  defp next(state, slot_in, slot_out, requests, proposals, decisions) do
    receive do
      {:request, command} -> 
        propose()
        next(state, slot_in, slot_out, MapSet.put(requests, command), proposals, decisions)
      {:decision, slot, command} ->
        for { slot_p, command_p } <- decisions do
        end

        propose()
        next(state, slot_in, slot_out, requests, proposals, MapSet.put(decisions, {slot, c}))
    end
  end

  defp propose(slot_in, slot_out) do
    WINDOW = 10
    propose_helper(window, slot_in, slot_out)
  end

  defp propose_helper(window, slot_in, slot_out) do

  end

  defp perform(command) do
    { client_id, command_id, op } = command
  end
end