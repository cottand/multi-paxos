# Nicolas D'Cotta (nd3018) and William Profit (wtp18)

defmodule Scout do
  @spec start(MapSet.t(pid), MapSet.t(pid), Util.ballot(), %{
          :monitor => pid,
          :node_num => integer,
          optional(any) => any
        }) :: no_return
  def start(leader, acceptors, ballot, config) do
    send(config.monitor, {:SCOUT_SPAWNED, config.node_num})

    for acceptor <- acceptors do
      Util.log(config, :DEBUG, "scout: sending :p1a to acceptor #{inspect(acceptor)}")
      send(acceptor, {:p1a, self(), ballot, config.node_num})
    end

    next(leader, acceptors, acceptors, ballot, MapSet.new(), config)
  end

  # pvalues :: MapSet.t({ballot, slot, command})
  @spec next(MapSet.t(pid), MapSet.t(pid), MapSet.t(pid), any(), Util.pvalues(), map()) :: any()
  defp next(leader, acceptors, waitfor, ballot, pvalues, config) do
    receive do
      # r :: MapSet.t {ballot, slot, command}
      {:p1b, acceptor, new_ballot, r} ->
        Util.log(
          config,
          :DEBUG,
          "scout: receievd p1b for ballot #{inspect(new_ballot)}, having #{inspect(ballot)}"
        )

        if new_ballot == ballot do
          # Util.log(config, :DEBUG, "scout: commands received are #{inspect r}, updating pvalues #{inspect pvalues}")
          pvalues = MapSet.union(pvalues, r)
          waitfor = MapSet.delete(waitfor, acceptor)

          waiting_still = MapSet.size(waitfor)
          all_acceptors = MapSet.size(acceptors)

          Util.log(
            config,
            :DEBUG,
            "scout: received p1b from #{all_acceptors - waiting_still}/#{all_acceptors}"
          )

          # TODO what happens when we have 2 servers only??
          if waiting_still < all_acceptors / 2 do
            # FIXME we never reach this - we only ever receive a single :p1b
            send(leader, {:adopted, ballot, pvalues})
            stop(config)
          end

          next(leader, acceptors, waitfor, ballot, pvalues, config)
        else
          send(leader, {:preempted, new_ballot})
          stop(config)
        end
    end
  end

  defp stop(config) do
    send(config.monitor, {:SCOUT_FINISHED, config.node_num})
    exit(:normal)
  end
end
