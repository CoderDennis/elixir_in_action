defmodule Todo.Server do
  use GenServer

  def start_link(todo_list_name) do
    IO.puts "Starting to-do server for #{todo_list_name}."
    GenServer.start_link(Todo.Server, todo_list_name)
  end

  def init(todo_list_name) do
    {:ok, {todo_list_name, Todo.Database.get(todo_list_name) || Todo.List.new}}
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def update_entry(todo_server, entry_id, updater_fun) do
    GenServer.cast(todo_server, {:update_entry, entry_id, updater_fun})
  end

  def delete_entry(todo_server, entry_id) do
    GenServer.cast(todo_server, {:delete_entry, entry_id})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def handle_cast({:add_entry, new_entry}, {todo_list_name, todo_list}) do
    new_state = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(todo_list_name, new_state)
    {:noreply, {todo_list_name, new_state}}
  end
  def handle_cast({:update_entry, entry_id, updater_fun}, {todo_list_name, todo_list}) do
    {:noreply, {todo_list_name, Todo.List.update_entry(todo_list, entry_id, updater_fun)}}
  end
  def handle_cast({:delete_entry, entry_id}, {todo_list_name, todo_list}) do
    {:noreply, {todo_list_name, Todo.List.delete_entry(todo_list, entry_id)}}
  end

  def handle_call({:entries, date}, _, {todo_list_name, todo_list}) do
    {:reply, Todo.List.entries(todo_list, date), {todo_list_name, todo_list}}
  end
end

