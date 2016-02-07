defmodule Todo.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    processes = [
      supervisor(Todo.Database, ["./persist/#{node_local_name}/"]),
      supervisor(Todo.ServerSupervisor, [])
    ]
    supervise(processes, strategy: :rest_for_one)
  end

  defp node_local_name() do
    Node.self
    |> Atom.to_string
    |> String.split("@", parts: 2)
    |> List.first
  end
end
