defmodule Broker do
  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "2000")
    storage = System.get_env("STORAGE") || File.cwd! <> "/storage.json"

    children = [
      {UDPServer, port},
      {TopicMap, storage}
    ]

    opts = [{:strategy, :one_for_one}]
    Supervisor.start_link(children, opts)
    # Supervisor.start_link([{UDPServer, port}], strategy: :one_for_one)
  end
end
