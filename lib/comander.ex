# Nicolas D'Cotta (nd3018) and William Profit (wtp18)

defmodule Commander do
  def start(leader_pid, acceptors, replicas, {ballot, slot, command}, config) do
    send(config.monitor, {:COMMANDER_SPAWNED, config.node_num})
    for acceptor <- acceptors, do: send(acceptor, {:p2a, self(), {ballot, slot, command}})
    next(leader_pid, acceptors, replicas, {ballot, slot, command}, acceptors, config)
  end

  defp next(leader_pid, acceptors, replicas, {ballot, slot, command}, acceptors_waiting, config) do
    receive do
      {:p2b, acceptor, new_ballot} ->
        if new_ballot == ballot do
          acceptors_waiting = MapSet.delete(acceptors_waiting, acceptor)

          if MapSet.size(acceptors_waiting) < MapSet.size(acceptors) / 2 do
            for replica <- replicas, do: send(replica, {:decision, slot, command})
            send(leader_pid, {:success_decision})
            exitC(config)
          end

          next(leader_pid, acceptors, replicas, {ballot, slot, command}, acceptors_waiting, config)
        else
          send(leader_pid, {:preempted, new_ballot})
          exitC(config)
        end
    end
  end

  defp exitC(config) do
    send config.monitor, {:COMMANDER_FINISHED, config.node_num }
    exit(:normal)
  end
end
