defmodule Scout do
  def start(leader, acceptors, ballot) do
    for acceptor <- acceptors, do: send(acceptor, {:p1a, self(), ballot})

    next(leader, acceptors, acceptors, ballot, MapSet.new())
  end

  defp next(leader, acceptors, waitfor, ballot, pvalues) do
    receive do
      {:p1b, acceptor, new_ballot, r} ->
        if new_ballot == ballot do
          pvalues = MapSet.put(pvalues, r)
          waitfor = MapSet.delete(waitfor, acceptor)

          if MapSet.size(waitfor) < MapSet.size(acceptors) / 2 do
            send leader, {:adopted, ballot, pvalues}
            exit :normal
          end
        else
          send leader, {:preempted, new_ballot}
          exit :normal
        end

        next(leader, waitfor, acceptors, ballot, pvalues)
    end

  end
end
