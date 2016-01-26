defmodule MultiDict do
  def new, do: %{}

  def add(dict, key, value) do
    Dict.update(dict, key, [value], &[value | &1])
  end

  def get(dict, key) do
    Dict.get(dict, key, [])
  end
end
