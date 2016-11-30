defmodule Indifferent.Path do

  @moduledoc false

  def expand(path) do
    expand(path, [])
  end

  def expand({{:., _, [Access, :get]}, _, [a, b]}, seen) do
    expand(a, []) ++ expand(b, seen)
  end

  def expand({{:., _, [a, b]}, _, []}, seen) do
    expand(a, []) ++ expand(b, seen)
  end

  def expand({a, _, nil}, seen) do
    [a | seen]
  end

  def expand([a], seen), do: expand(a, seen)

  def expand(any, seen) when is_atom(any) or is_binary(any) or is_number(any) do
    [any | seen]
  end

end
