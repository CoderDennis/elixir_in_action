defmodule Todo.Database do
  use GenServer

  def start(db_folder) do
    GenServer.start(__MODULE__, db_folder, name: :database_server)
  end

  def store(key, data) do
    GenServer.cast(:database_server, {:store, key, data})
  end

  def get(key) do
    GenServer.call(:database_server, {:get, key})
  end

  def init(db_folder) do
    File.mkdir_p(db_folder)
    workers =
    (0..2
      |> Stream.map(fn i ->
        {:ok, pid} = Todo.DatabaseWorker.start(db_folder)
        {i, pid}
      end)
      |> Enum.into(%{})
    )
    IO.inspect(workers)
    {:ok, workers}
  end

  def handle_cast({:store, key, _} = msg, workers) do
    GenServer.cast(get_worker(workers, key), msg)
    {:noreply, workers}
  end

  def handle_call({:get, key} = msg, _, workers) do
    data = GenServer.call(get_worker(workers, key), msg)
    {:reply, data, workers}
  end

  defp get_worker(workers, key), do: workers[:erlang.phash2(key, 3)]
end
