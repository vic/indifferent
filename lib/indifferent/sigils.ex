defmodule Indifferent.Sigils.Internal do
  @moduledoc false # internal api

  def sigil_i(sigil, modifiers, env) do
    path = sigil_to_quoted!(sigil, env)
    read_sigil_i(path, modifiers)
  end

  def sigil_i(data, sigil, modifiers, env) do
    path = sigil_to_quoted!(sigil, env)
    piped_sigil_i(data, path, modifiers)
  end

  def sigil_I(sigil, modifiers, env) do
    path = sigil_to_quoted!(sigil, env) |> Macro.escape
    quote do
      [fn
        :get, data, next ->
          unquote(__MODULE__).get_in(
            data, next, unquote(path), unquote(modifiers))
        :get_and_update, data, next ->
          unquote(__MODULE__).get_and_update_in(
            data, next, unquote(path), unquote(modifiers))
      end]
    end
  end

  defp sigil_to_quoted!({:<<>>, _, [path_code]}, env) do
    Code.string_to_quoted!(path_code, file: env.file, line: env.line)
  end

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

  defp named_reads_quoted(names_and_paths, modifiers) do
    for {name, path} <- names_and_paths, do: {name, read_quoted(path, modifiers)}
  end

  defp tuple_read_quoted(paths, modifiers) do
    reads = for path <- paths, do: read_quoted(path, modifiers)
    quote do
      {unquote_splicing(reads)}
    end
  end

  defp read_quoted(path, modifiers) do
    [data | keys] = Indifferent.Path.flatten(path)
    indifferent_data = quote do
      unquote(__MODULE__).indifferent(unquote(data), unquote(modifiers))
    end
    quote do
      Indifferent.get_in(unquote(indifferent_data), unquote(keys))
    end
  end

  defp named_path_quoted(data, names_and_paths, modifiers) do
    var = Macro.var(:data, __MODULE__)
    matches = for {name, path} <- names_and_paths,
      do: {name, path_quoted(var, path, modifiers)}
    quote do
      fn unquote(var) -> unquote(matches) end.(unquote(data))
    end
  end

  defp tuple_path_quoted(data, paths, modifiers) do
    var = Macro.var(:data, __MODULE__)
    matches = for path <- paths, do: path_quoted(var, path, modifiers)
    quote do
      fn unquote(var) -> {unquote_splicing(matches)} end.(unquote(data))
    end
  end

  defp piped_sigil_i(data, path, modifiers)
  defp piped_sigil_i(data, {:{}, _, paths}, modifiers),
  do: tuple_path_quoted(data, paths, modifiers)
  defp piped_sigil_i(data, {a, b}, modifiers),
  do: tuple_path_quoted(data, [a, b], modifiers)
  defp piped_sigil_i(data, paths, modifiers) do
    if Keyword.keyword?(paths),
    do: named_path_quoted(data, paths, modifiers),
    else: path_quoted(data, paths, modifiers)
  end


  defp read_sigil_i(path, modifiers)
  defp read_sigil_i({:{}, _, paths}, modifiers),
  do: tuple_read_quoted(paths, modifiers)
  defp read_sigil_i({a, b}, modifiers),
  do: tuple_read_quoted([a, b], modifiers)
  defp read_sigil_i(path, modifiers) do
    if Keyword.keyword?(path),
    do: named_reads_quoted(path, modifiers),
    else: read_quoted(path, modifiers)
  end

  defp path_quoted(data, path, modifiers) do
    path = Macro.escape(path)
    quote do
      unquote(__MODULE__).get_in(
        unquote(data), fn x -> x end, unquote(path), unquote(modifiers))
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

      iex> data = %{"a" => 1, "b" => %{"c" => 2}}
      iex> ~i({data.a, data.b.c})
      {1, 2}

       iex> data = %{"a" => [b: {10, 20}]}
       iex> ~i([x: data.a.b[0], y: data.a.b[1]])
       [x: 10, y: 20]

  """
  defmacro sigil_i(sigil, modifiers) do
    __MODULE__.Internal.sigil_i(sigil, modifiers, __CALLER__)
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
    __MODULE__.Internal.sigil_I(sigil, modifiers, __CALLER__)
  end

  @doc """
  Sigil version of `Indifferent.path/2`

  ## Examples

      iex> data = %{"a" => [b: {10, 20}]}
      iex> data |> ~i(a.b[1])
      20

      iex> data = %{"a" => 1, "b" => %{"c" => 2}}
      iex> data |> ~i({a, b.c})
      {1, 2}

      iex> data = %{"a" => [b: {10, 20}]}
      iex> data |> ~i([x: a.b[1]])
      [x: 20]

  """
  defmacro sigil_i(data, sigil, modifiers) do
    __MODULE__.Internal.sigil_i(data, sigil, modifiers, __CALLER__)
  end

end
