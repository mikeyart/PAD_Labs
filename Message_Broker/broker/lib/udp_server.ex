defmodule UDPServer do
  # Our module is going to use the DSL (Domain Specific Language) for Gen(eric) Servers
  use GenServer

  # We need a factory method to create our server process
  # it takes a single parameter `port` which defaults to `2052`
  # This runs in the caller's context
  def start_link(port \\ 2052) do
    # Start 'er up
    GenServer.start_link(__MODULE__, port)
  end

  # Initialization that runs in the server context (inside the server process right after it boots)
  def init(port) do
  
    :gen_udp.open(port, [:binary, active: true])
  end

  # define a callback handler for when gen_udp sends us a UDP packet
  def handle_info({:udp, _socket, address, port, data}, socket) do
    # punt the data to a new function that will do pattern matching
    handle_packet(data, socket, {address, port})
  end

  # pattern match the "quit" message
  defp handle_packet("quit\n", socket, _address) do
    IO.puts("Received: quit")

    # close the socket
    :gen_udp.close(socket)

    # GenServer will understand this to mean we want to stop the server
    # action: :stop
    # reason: :normal
    # new_state: nil, it doesn't matter since we're shutting down :(
    {:stop, :normal, nil}
  end

  # fallback pattern match to handle all other (non-"quit") messages
  defp handle_packet(data, socket, {address, port}) do
    data = String.trim(data)
    # print the message
    IO.puts("Received: #{data}")

    case data do
      "sub " <> topic ->
        TopicMap.subscribe(topic, {address, port})

        "unsub " <> topic ->
          TopicMap.unsubscribe(topic, {address, port})

      "pub " <> topic_with_message ->
        [topic | rest] = String.split(topic_with_message, " ")
        message = Enum.join(rest, " ")
        clients = TopicMap.get(topic)
        Enum.each(clients, fn {address, port} ->
          :gen_udp.send(socket, address, port, message <> "\n")
        end)

      _ ->
        :gen_udp.send(socket, address, port, "Unknown message, gtfo \n")
    end


    {:noreply, socket}
  end
end
