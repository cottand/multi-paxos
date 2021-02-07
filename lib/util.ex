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

  # node_init

  # Whether this ballot is greater than the other, in lexicographic order
  @spec ballot_greater?({integer() | nil, pid()}, {integer() | nil, pid()}) :: boolean
  def ballot_greater?({nil, _}, {_, _}), do: false

  def ballot_greater?({_, _}, {nil, _}), do: true

  def ballot_greater?({this_num, this_pid}, {other_num, other_pid}) do
    if this_num != other_num do
      this_num > other_num
    else
      # Is this case reachable? I think so
      IO.puts("WARN Got identical ballot numbers from #{inspect {this_pid, other_pid}}")
      exit(:crash)
      :TODO
    end
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
