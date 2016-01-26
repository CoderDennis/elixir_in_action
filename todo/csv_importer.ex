defmodule TodoList.CsvImporter do

  def import(filename) do
    File.stream!(filename, [:utf8])
    |> Stream.map(&String.replace(&1, "\n", ""))
    |> Stream.map(&String.split(&1, ","))
    |> Stream.map(fn [d, t] -> %{date: parse_date(d), title: t} end)
    |> TodoList.new()
  end

  def parse_date(date_string) do
    date_string
    |> String.split("/")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end

end
