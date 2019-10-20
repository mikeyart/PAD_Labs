defmodule TopicMap do
  use GenServer

  # Client

  def start_link(file_path) do
    GenServer.start_link(__MODULE__, file_path, name: TopicMap)
  end

  def subscribe(topic, address) do
    GenServer.cast(TopicMap, {:subscribe, topic, address})
  end

  def unsubscribe(topic, address) do
    GenServer.cast(TopicMap, {:unsubscribe, topic, address})
  end

  def get(topic) do
    GenServer.call(TopicMap, {:get, topic})
  end

  # Server (callbacks)

  def init(path) do
    map = if File.exists?(path) do
      path |> File.read!() |> Jason.decode!() |> deserialize()
    else
      %{}
    end

    {:ok, {map, path}}
  end

  def handle_call({:get, topic}, _from, {map, _} = state) do
    result = Map.get(map, topic, [])
    {:reply, result, state}
  end

  def handle_cast({:subscribe, topic, address}, {map, path}) do
    new_map = Map.update(map, topic, [address], fn list -> [address | list] end)
    IO.puts("Subscribed new client to #{topic}")
    persist(new_map, path)
    {:noreply, {new_map, path}}
  end

  def handle_cast({:unsubscribe, topic, address}, {map, path}) do
    new_map = if Map.has_key?(map, topic) do
      IO.puts("The client unsubscribed from #{topic}")
      Map.update!(map, topic, fn list -> List.delete(list, address) end)
    else
      map
    end

    persist(new_map, path)
    {:noreply, {new_map, path}}
  end

  defp serialize(map) do
    Map.new(map, fn {topic, list} ->
      {topic, Enum.map(list, fn {address, port} -> [Tuple.to_list(address), port] end)}
    end)

  end

  defp deserialize(map) do
    Map.new(map, fn {topic, list} ->
      {topic, Enum.map(list, fn [address, port] -> {List.to_tuple(address), port} end)}
    end)
  end

  defp persist(map, path) do
    content = serialize(map) |> Jason.encode!()
    IO.inspect(content)
    File.write!(path, content)
  end
end
