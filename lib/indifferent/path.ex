defmodule Indifferent.Path do

  @moduledoc false

  def expand(path) do
    [head | tail] = flatten(path)
    [literal(head) | tail]
  end

  def flatten(path), do: flatten(path, [])

  defp literal({a, _, x}) when x == nil or x == Elixir, do: a
  defp literal(a), do: a

  defp flatten({{:., _, [Access, :get]}, _, [a, b]}, seen) do
    flatten(a, []) ++ [b | seen]
  end

  defp flatten(a = {{:., _, [{:__aliases__, _, _}, _]}, _, _}, seen) do
    [a | seen]
  end

  defp flatten({:__aliases__, _, [a, b]}, seen) do
    flatten(a, []) ++ flatten(b, seen)
  end

  defp flatten({{:., _, [a, b]}, _, []}, seen) do
    flatten(a, []) ++ flatten(b, seen)
  end

  defp flatten(a = {_, _, x}, seen) when is_list(x) do
    [a | seen]
  end

  defp flatten(a = {_, _, x}, seen) when is_atom(x) do
    [a | seen]
  end

  defp flatten([a], seen), do: flatten(a, seen)

  defp flatten(any, seen) when is_atom(any) or is_binary(any) or is_number(any) do
    [any | seen]
  end

end
