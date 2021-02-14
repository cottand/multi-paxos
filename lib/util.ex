# distributed algorithms, n.dulay, 29 jan 2021
# coursework, paxos made moderately complex
#
# various helper functions

defmodule Util do
  def lookup(name) do
    addresses = :inet_res.lookup(name, :in, :a)
    # get octets for 1st ipv4 address
    {a, b, c, d} = hd(addresses)
    :"#{a}.#{b}.#{c}.#{d}"
  end

  # lookup

  def node_ip_addr do
    # get interfaces
    {:ok, interfaces} = :inet.getif()
    # get data for 1st interface
    {address, _gateway, _mask} = hd(interfaces)
    # get octets for address
    {a, b, c, d} = address
    "#{a}.#{b}.#{c}.#{d}"
  end

  # node_ip_addr

  # --------------------------------------------------------------------------

  def random(n) do
    Enum.random(1..n)
  end

  def unzip3(triples) do
    :lists.unzip3(triples)
  end

  def node_string() do
    "#{node()} (#{node_ip_addr()})"
  end

  # --------------------------------------------------------------------------

  # nicely stop and exit the node
  def node_exit do
    # System.halt(1) for a hard non-tidy node exit
    System.stop(0)
  end

  # node_exit

  def halt(message) do
    IO.puts("Exiting Node #{node()} - #{message}")
    Util.node_exit()
  end

  #  halt

  def exit_after(duration) do
    Process.sleep(duration)
    Util.halt("maxtime #{duration} reached")
  end

  # exit_after

  # get node arguments and spawn a process to exit node after max_time
  def node_init do
    config = Map.new()
    config = Map.put(config, :node_suffix, Enum.at(System.argv(), 0))
    config = Map.put(config, :max_time, String.to_integer(Enum.at(System.argv(), 1)))
    config = Map.put(config, :debug_level, String.to_integer(Enum.at(System.argv(), 2)))
    config = Map.put(config, :n_servers, String.to_integer(Enum.at(System.argv(), 3)))
    config = Map.put(config, :n_clients, String.to_integer(Enum.at(System.argv(), 4)))
    config = Map.put(config, :start_function, :"#{Enum.at(System.argv(), 6)}")

    config = Map.merge(config, Configuration.params(:"#{Enum.at(System.argv(), 5)}"))

    spawn(Util, :exit_after, [config.max_time])
    config
  end

  def debug_level_from(atom_or_int) do
    case(atom_or_int) do
      :DEBUG -> 0
      :INFO -> 1
      :WARN -> 2
      :LIFE -> 3
      other -> other
    end
  end

  def log(config, level, message) do
    level = debug_level_from(level)
    if level >= config.debug_level, do: IO.puts("#{node()}: #{message}")
  end

  # node_init
  # {p_number, pid}
  @type ballot :: {integer(), pid()} | :bottom

  # returns a deterministic float for a ballot, where a ballot with a higher integer
  # is always bigger than a ballot with a smaller integer independently of PID,
  # but where two ballots with the same integer can be compared thanks to their PID's
  # hash deterministically
  @spec ballot_as_num(ballot()) :: float()
  def ballot_as_num(:bottom), do: -1000.0

  def ballot_as_num({num, pid}) do
    pid = to_charlist(inspect(pid))
    pid = Enum.reduce(pid, fn char, acc -> char * 31 + acc end)
    num * 100.0 + (100.0 / pid)
  end

  # Whether this ballot is greater than the other, in lexicographic order
  @spec ballot_greater?(ballot(), ballot()) :: boolean
  def ballot_greater?(:bottom, _), do: false

  def ballot_greater?(_, :bottom), do: true

  def ballot_greater?({this_num, this_pid}, {other_num, other_pid}) do
    if this_num != other_num do
      this_num > other_num
    else
      # numbers are equal! compare hashes from PIDs
      ballot_as_num({this_num, this_pid}) > ballot_as_num({other_num, other_pid})
    end
  end

  # { client_id, command_id, operation }
  # There cannont be two commands with the same client_id and command_id
  @type command :: {pid, integer, any}

  @type proposal_set :: map()

  # { ballot, slot, command }
  @type pvalues :: MapSet.t({ballot(), integer(), command()})

  # { slot, command }
  @type proposal :: {integer(), command()}

  @spec add_proposal(proposal_set(), proposal()) :: proposal_set()
  def add_proposal(proposal_set, {slot, command}) do
    Map.put(proposal_set, slot, command)
  end

  @spec update_with(proposal_set(), proposal_set()) :: proposal_set()
  def update_with(xs, ys) do
    elems_of_xs_not_in_ys =
      Map.new(Enum.filter(xs, fn {x_key, _} -> !Map.has_key?(ys, x_key) end))

    Map.merge(ys, elems_of_xs_not_in_ys)
  end

  # I really hope this one works ;-;
  @spec pmax(pvalues(), map) :: proposal_set()
  def pmax(pvalues, config) do
    # map of s => [{b, c}]
    log config, :DEBUG, "calculating pmax of #{inspect pvalues}"
    by_proposal = Enum.group_by(pvalues, fn {_b, s, _c} -> s end, fn {b, _s, c} -> {b, c} end)
    not_reached = fn -> raise "not reached" end

    slot_with_highest_ballot = fn {slot, ballots} ->
      {slot, Enum.max_by(ballots, fn {b, _} -> ballot_as_num(b) end, not_reached)}
    end

    # list [{s, {b, c}}]
    max = Enum.map(by_proposal, slot_with_highest_ballot)
    # map of {s, c} (ie, a proposal_set)
    Map.new(Enum.map(max, fn {s, {_b, c}} -> {s, c} end))
  end
end

# Util

"""
defp read_network_map(file_name) do
  # line = <node_num> <hostname> pair
  # returns Map of node_num to hostname entries

  stream = File.stream!(file_name) |> Stream.map(&String.split/1)

  for [first, second | _] <- stream, into: %{} do
    { (first |> String.to_integer), second }
  end
end # read_network_map
"""
