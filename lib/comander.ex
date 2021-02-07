defmodule Commander do
  def start(leader_pid, acceptors, replicas, {ballot, slot, command}) do
    for acceptor <- acceptors, do: send(acceptor, {:p2a, self(), {ballot, slot, command}})
    next(leader_pid, acceptors, replicas, {ballot, slot, command}, acceptors)
  end

  defp next(leader_pid, acceptors, replicas, {ballot, slot, command}, acceptors_waiting) do
    receive do
      {:p2b, acceptor, new_ballot} ->
        if new_ballot == ballot do
          acceptors_waiting = MapSet.delete(acceptors_waiting, acceptor)

          if MapSet.size(acceptors_waiting) < MapSet.size(acceptors) / 2   do
            for replica <- replicas, do: send(replica, {:decision, slot, command})
            exit :normal
          end

          next(leader_pid, acceptors, replicas, {ballot, slot, command}, acceptors_waiting)
        else
          send(leader_pid, {:preempted, new_ballot})
          exit :normal
        end
    end
  end
end
