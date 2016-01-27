defmodule ServerProcess do
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init
      loop(callback_module, initial_state)
    end)
  end

  def call(server_pid, request) do
    send(server_pid, {:call, request, self})

    receive do
      {:response, response} -> response
    end
  end

  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
    :ok
  end

  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(request,
                                                            current_state
        )

        send(caller, {:response, response})

        loop(callback_module, new_state)
      {:cast, request} ->
        new_state = callback_module.handle_cast(request,
                                                current_state
        )

        loop(callback_module, new_state)
    end
  end
end

defmodule TodoServer do
  def start do
    Process.register(ServerProcess.start(TodoServer), :todo_server)
    :ok
  end

  def init do
    TodoList.new
  end

  def add_entry(new_entry) do
    ServerProcess.cast(:todo_server, {:add_entry, new_entry})
  end

  def update_entry(entry_id, updater_fun) do
    ServerProcess.cast(:todo_server, {:update_entry, entry_id, updater_fun})
  end

  def delete_entry(entry_id) do
    ServerProcess.cast(:todo_server, {:delete_entry, entry_id})
  end

  def entries(date) do
    ServerProcess.call(:todo_server, {:entries, date})
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    TodoList.add_entry(todo_list, new_entry)
  end
  def handle_cast({:update_entry, entry_id, updater_fun}, todo_list) do
    TodoList.update_entry(todo_list, entry_id, updater_fun)
  end
  def handle_cast({:delete_entry, entry_id}, todo_list) do
    TodoList.delete_entry(todo_list, entry_id)
  end

  def handle_call({:entries, date}, todo_list) do
    {TodoList.entries(todo_list, date), todo_list}
  end
end

defmodule TodoList do
  defstruct auto_id: 1, entries: %{}

  def new(entries \\[]) do
    Enum.reduce(
      entries,
      %TodoList{},
      fn(entry, todo_list_acc) ->
        add_entry(todo_list_acc, entry)
      end)
  end

  def add_entry(%TodoList{entries: entries, auto_id: auto_id} = todo_list,
                entry) do
    entry = Map.put(entry, :id, auto_id)
    new_entries = Map.put(entries, auto_id, entry)

    %TodoList{todo_list |
              entries: new_entries,
              auto_id: auto_id + 1}
  end

  def entries(%TodoList{entries: entries}, date) do
    entries
    |> Stream.filter(fn({_, entry}) -> entry.date == date end)
    |> Enum.map(fn({_, entry}) -> entry end)
  end

  def update_entry(%TodoList{entries: entries} = todo_list,
                   entry_id, updater_fun) do
    case entries[entry_id] do
      nil -> todo_list
      old_entry ->
        old_entry_id = old_entry.id
        new_entry = %{id: ^old_entry_id} = updater_fun.(old_entry)
        new_entries = Map.put(entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  def delete_entry(%TodoList{entries: entries} = todo_list,
                   entry_id) do
    new_entries = Map.delete(entries, entry_id)
    %TodoList{todo_list | entries: new_entries}
  end
end

defimpl Collectable, for: TodoList do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    TodoList.add_entry(todo_list, entry)
  end
  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(_todo_list, :halt), do: :ok
end

