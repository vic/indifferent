defprotocol Indifferent.Accessor do
  def key?(data, key)

  def getter(data, key)
  def setter(data, key)
  def popper(data, key)
end

defimpl Indifferent.Accessor, for: Indifferent.Access do
  def key?(%{on: data}, key), do: Indifferent.Accessor.key?(data, key)
  def getter(%{on: data}, key), do: Indifferent.Accessor.getter(data, key)
  def setter(%{on: data}, key), do: Indifferent.Accessor.setter(data, key)
  def popper(%{on: data}, key), do: Indifferent.Accessor.popper(data, key)
end


defimpl Indifferent.Accessor, for: Map do
  def key?(data, key), do: Map.has_key?(data, key)

  def getter(data, key), do: fn -> Map.get(data, key) end
  def setter(data, key), do: fn v -> Map.put(data, key, v) end
  def popper(data, key), do: fn -> Map.pop(data, key) end
end

defimpl Indifferent.Accessor, for: List do
  def key?(_data, key) when not is_integer(key), do: false
  def key?(data, key), do: key < length(data)

  def getter(data, key) when is_integer(key), do: fn -> Enum.at(data, key) end
  def setter(data, key) when is_integer(key), do: fn v -> List.replace_at(data, key, v) end
  def popper(data, key) when is_integer(key), do: fn -> {Enum.at(data, key), List.delete_at(data, key)} end
end


defimpl Indifferent.Accessor, for: Tuple do
  def key?(_data, key) when not is_integer(key), do: false
  def key?(data, key), do: key < tuple_size(data)

  def getter(data, key) when is_integer(key), do: fn -> elem(data, key) end
  def setter(data, key) when is_integer(key), do: fn v -> put_elem(data, key, v) end
  def popper(data, key) when is_integer(key), do: fn -> {elem(data, key), Tuple.delete_at(data, key)} end
end

defmodule Indifferent.Accessor.Keyword do
  @moduledoc false

  def key?(_data, key) when not is_atom(key), do: false
  def key?(data, key), do: Keyword.has_key?(data, key)

  def getter(data, key) when is_atom(key), do: fn -> data[key] end
  def setter(data, key) when is_atom(key), do: fn v -> Keyword.put(data, key, v) end
  def popper(data, key) when is_atom(key), do: fn -> {data[key], Keyword.drop(data, [key])} end
end
