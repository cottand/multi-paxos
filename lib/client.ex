
# distributed algorithms, n.dulay 29 jan 2021
# coursework, paxos made moderately complex

defmodule Client do

def start config, client_num, replicas do
  config = Configuration.node_id(config, "Client", client_num)
  Debug.starting(config)
  Process.send_after self(), :CLIENT_STOP, config.client_stop

  quorum =
    case config.client_send do
      :round_robin -> 1
      :broadcast   -> config.n_servers
      :quorum      -> div config.n_servers + 1, 2
    end
  next config, client_num, replicas, 0, quorum
end # start

defp next config, client_num, replicas, sent, quorum do
  # Setting client_sleep to 0 may overload the system
  # with lots of requests and lots of spawned rocesses.

  receive do
  :CLIENT_STOP ->
    IO.puts "  Client #{client_num} going to sleep, sent = #{sent}"
    Process.sleep :infinity

  after config.client_sleep ->
    account1 = Enum.random 1 .. config.n_accounts
    account2 = Enum.random 1 .. config.n_accounts
    amount   = Enum.random 1 .. config.max_amount
    transaction  = { :MOVE, amount, account1, account2 }

    sent = sent + 1
    cmd = { self(), sent, transaction }

    for r <- 1..quorum do
        replica = Enum.at replicas, rem(sent+r, config.n_servers)
        send replica, { :CLIENT_REQUEST, cmd }
    end

    if sent == config.max_requests, do: send self(), :CLIENT_STOP

    receive_replies()
    next config, client_num, replicas, sent, quorum
  end
end # next

defp receive_replies do
  receive do
  { :CLIENT_REPLY, _cid, _result } -> receive_replies()   # discard
  after 0 -> :return
  end # receive
end # receive_replies

end # Client

