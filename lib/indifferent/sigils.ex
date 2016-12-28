defmodule Indifferent.Sigils.Internal do
  @moduledoc false # internal api

  def sigil_to_quoted!({:<<>>, _, [path_code]}, env) do
    Code.string_to_quoted!(path_code, file: env.file, line: env.line)
  end

  # internal api

  def get_in(data, next, path, modifiers) do
    data = indifferent(data, modifiers)
    keys = Indifferent.Path.expand(path)
    next.(Indifferent.get_in(data, keys))
  end

  def get_and_update_in(data, next, path, modifiers) do
    data = indifferent(data, modifiers)
    keys = Indifferent.Path.expand(path)
    Indifferent.get_and_update_in(data, keys, next)
  end

  def named_reads_quoted(names_and_paths, modifiers) do
    for {name, path} <- names_and_paths, do: {name, read_quoted(path, modifiers)}
  end

  def read_quoted(path, modifiers) do
    [data | keys] = Indifferent.Path.flatten(path)
    indifferent_data = quote do
      unquote(__MODULE__).indifferent(unquote(data), unquote(modifiers))
    end
    quote do
      Indifferent.get_in(unquote(indifferent_data), unquote(keys))
    end
  end

  def indifferent(data, _modifiers = '') do
    Indifferent.access(data)
  end
end

defmodule Indifferent.Sigils do
  @moduledoc """
  Provide sigils for indifferent access.

  """

  @doc """
  Sigil version of `Indifferent.read/1`

  ## Examples

       iex> data = %{"a" => [b: {10, 20}]}
       iex> ~i(data.a.b[1])
       20

       iex> data = %{"a" => [b: {10, 20}]}
       iex> ~i([x: data.a.b[0], y: data.a.b[1]])
       [x: 10, y: 20]

  """
  defmacro sigil_i(sigil, modifiers) do
    import __MODULE__.Internal
    path = sigil_to_quoted!(sigil, __CALLER__)
    if Keyword.keyword?(path) do
      named_reads_quoted(path, modifiers)
    else
      read_quoted(path, modifiers)
    end
  end

  @doc """
  Sigil version of `Indifferent.path/1`

  ## Examples

       iex> data = %{"a" => [b: {10, 20}]}
       iex> Kernel.get_in(data, ~I(a.b[1]))
       20

       iex> data = %{"a" => [b: {10, 20}]}
       iex> Kernel.pop_in(data, ~I(a.b))
       {{10, 20}, %{"a" => []}}

  """
  defmacro sigil_I(sigil, modifiers) do
    import __MODULE__.Internal
    path = sigil_to_quoted!(sigil, __CALLER__) |> Macro.escape
    quote do
      [fn
        :get, data, next ->
          unquote(__MODULE__).Internal.get_in(
            data, next, unquote(path), unquote(modifiers))
        :get_and_update, data, next ->
          unquote(__MODULE__).Internal.get_and_update_in(
            data, next, unquote(path), unquote(modifiers))
      end]
    end
  end

  @doc """
  Sigil version of `Indifferent.path/2`

  ## Examples

       iex> data = %{"a" => [b: {10, 20}]}
       iex> data |> ~i(a.b[1])
       20

  """
  defmacro sigil_i(data, sigil, modifiers) do
    import __MODULE__.Internal
    path = sigil_to_quoted!(sigil, __CALLER__) |> Macro.escape
    quote do
      unquote(__MODULE__).Internal.get_in(
        unquote(data), fn x -> x end, unquote(path), unquote(modifiers))
    end
  end

end
