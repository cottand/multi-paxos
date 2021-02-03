
# distributed algorithms, n.dulay, 29 jan 2021
# coursework, paxos made moderately complex
#
# various helper functions

defmodule Util do

def lookup(name) do 
  addresses = :inet_res.lookup(name,:in,:a) 
  {a, b, c, d} = hd(addresses) 		# get octets for 1st ipv4 address
  :"#{a}.#{b}.#{c}.#{d}"
end # lookup

def node_ip_addr do
  {:ok, interfaces} = :inet.getif()		# get interfaces
  {address, _gateway, _mask}  = hd(interfaces)	# get data for 1st interface
  {a, b, c, d} = address   			# get octets for address
  "#{a}.#{b}.#{c}.#{d}"
end # node_ip_addr

# --------------------------------------------------------------------------
 
def random(n)       do Enum.random 1..n end
def unzip3(triples) do :lists.unzip3(triples) end

def node_string()   do "#{node()} (#{node_ip_addr()})" end
 
# --------------------------------------------------------------------------

def node_exit do 	# nicely stop and exit the node
  System.stop(0)	# System.halt(1) for a hard non-tidy node exit
end # node_exit

def halt(message) do
  IO.puts "Exiting Node #{node()} - #{message}"
  Util.node_exit()
end # halt

def exit_after(duration) do
  Process.sleep(duration)
  Util.halt "maxtime #{duration} reached"
end # exit_after

def node_init do  # get node arguments and spawn a process to exit node after max_time
  config = Map.new
  config = Map.put config, :node_suffix, Enum.at(System.argv, 0)
  config = Map.put config, :max_time,    String.to_integer(Enum.at(System.argv, 1))
  config = Map.put config, :debug_level, String.to_integer(Enum.at System.argv, 2) 
  config = Map.put config, :n_servers,   String.to_integer(Enum.at System.argv, 3)
  config = Map.put config, :n_clients,   String.to_integer(Enum.at System.argv, 4) 
  config = Map.put config, :start_function, :'#{Enum.at(System.argv, 6)}'

  config = Map.merge config, Configuration.params(:'#{Enum.at System.argv, 5}')

  spawn(Util, :exit_after, [config.max_time])
  config
end # node_init

end # Util 


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


