defmodule Todo.Database do
  use GenServer

  def start(db_folder) do
    IO.puts "Starting database server."
    GenServer.start(__MODULE__, db_folder, name: :database_server)
  end

  def store(key, data) do
    key
    |> choose_worker
    |> Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker
    |> Todo.DatabaseWorker.get(key)
  end

  defp choose_worker(key) do
    GenServer.call(:database_server, {:choose_worker, key})
  end

  def init(db_folder) do
    {:ok, start_workers(db_folder)}
  end

  defp start_workers(db_folder) do
    for i <- 0..2, into: %{} do
      {:ok, pid} = Todo.DatabaseWorker.start(db_folder)
      {i, pid}
    end
  end

  def handle_call({:choose_worker, key}, _, workers) do
    {:reply, workers[:erlang.phash2(key, 3)], workers}
  end

  def handle_info(:stop, workers) do
    workers
    |> Enum.each(fn {_, pid} -> send(pid, :stop) end)

    {:stop, :normal, %{}}
  end
  def handle_info(_, state), do: {:noreply, state}
end
