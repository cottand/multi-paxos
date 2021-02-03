
# distributed algorithms, n.dulay, 29 jan 2021
# coursework, paxos made moderately complex
#
# some helper functions for debugging 

defmodule Debug do

def info(config, message, verbose \\ 1) do
  if config.debug_level >= verbose do IO.puts message end
end # log

def map(config, themap, verbose \\ 1) do
  if config.debug_level >= verbose do
    Enum.each(themap, fn ({key, value}) -> IO.puts "  #{key} #{inspect value}" end)
  end
end # map

def starting(config, verbose \\ 0) do
  if config.debug_level >= verbose do
    IO.puts "--> Starting #{config.node_name} at #{config.node_location}"
  end
end # starting

def letter(config, letter, verbose \\ 3) do
  if config.debug_level >= verbose do IO.write letter end
end # letter

def mapstring(map) do
  for {key, value} <- map, into: "" do "\n  #{key}\t #{inspect value}" end
end # mapstring

end # Debug

