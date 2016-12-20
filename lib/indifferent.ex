defmodule Indifferent do

  @doc ~S"""
  Creates an indifferent accessor for the given data structure.

  Options can be `key_transforms:` and `value_transforms:`.
  See `Indifferent.Transform`

  `key_transforms` are a list of functions for casting indifferent keys
  for example converting an string to an existing atom, these functions
  must return `{:ok, new_key}` if conversion was possible.

  ## Examples

      iex> i = Indifferent.access(%{"a" => 1})
      iex> i[:a]
      1

      iex> i = Indifferent.access(%{"a" => 1},
      ...>   key_transforms: [fn x, _indifferent -> {:ok, String.downcase(x)} end])
      iex> i["A"]
      1

  """
  def access(data, options \\ []) do
    indifferent = %Indifferent.Access{}
    keys   = Keyword.get(options, :key_transforms, indifferent.key_transforms)
    values = Keyword.get(options, :value_transforms, indifferent.value_transforms)
    wrap(data, %Indifferent.Access{key_transforms: keys, value_transforms: values})
  end


  @doc ~S"""
  Returns a function for accessing an indifferent item.

  Intended to be used with Kernel access functions.

  ## Examples

      iex> Kernel.get_in(%{"a" => 1}, [Indifferent.at(:a)])
      1

      iex> keys = [:a, :b] |> Enum.map(&Indifferent.at/1)
      iex> Kernel.get_and_update_in(%{"a" => %{"b" => 2}}, keys, fn x -> {x * 3, x * 4} end)
      {6, %{"a" => %{"b" => 8}}}

      iex> Kernel.pop_in(%{"a" => 1}, [Indifferent.at(:a)])
      {1, %{}}

  """
  def at(key) do
    Indifferent.Access.at(key)
  end

  @doc ~S"""
  Given a data structure and a path, fetches the corresponding value.

  ## Examples

    iex> %{"a" => 1, "b" => %{"c" => 2}} |> Indifferent.path(b.c)
    2

    iex> %{"b" => %{"c" => %{"d" => %{"e" => 4}}}} |> Indifferent.path(b["c"][:d].e)
    4

    iex> [1, 2] |> Indifferent.path(0)
    1

    iex> {1, 2} |> Indifferent.path(0)
    1

    iex> [1, {2, 3}] |> Indifferent.path([1][0])
    2

    iex> [1, [2, 3]] |> Indifferent.path([1][-1])
    3

    iex> [9, %{"c" => {:ok, %{"e" => 4}}}] |> Indifferent.path(1.c["1"].e)
    4

  """
  defmacro path(data, path) do
    keys = Indifferent.Path.expand(path)
    quote do
      Indifferent.get_in(unquote(data), unquote(keys))
    end
  end

  @doc ~S"""
  Returns an accessor-function for the given path, intended to be used by Kernel functions.

  ## Examples

     iex> Kernel.get_in(%{"a" => {0, 1}}, Indifferent.path(a["1"]))
     1

  """
  defmacro path(path) do
    keys = Indifferent.Path.expand(path)
    quote do
      unquote(keys) |> Enum.map(&Indifferent.at/1)
    end
  end


  def wrap(data, indifferent)
  def wrap(indifferent = %Indifferent.Access{}, _), do: indifferent
  def wrap(data, %Indifferent.Access{key_transforms: key_trans, value_transforms: value_trans}),
  do: %Indifferent.Access{on: data, key_transforms: key_trans, value_transforms: value_trans}

  def unwrap(indifferent)
  def unwrap(%Indifferent.Access{on: data}), do: data
  def unwrap(any), do: any


  @doc ~S"""
  Auto wrap version of `Kernel.get_in`

  ## Examples

      iex> Indifferent.get_in(%{"a" => %{"x" => 1}}, [:a])
      %{"x" => 1}

      iex> Indifferent.get_in(%{"a" => %{"x" => 1}}, [:a, :x])
      1

  """
  def get_in(data, keys),
  do: Kernel.get_in(access(data), keys) |> unwrap

  @doc ~S"""
  Auto wrap version of `Kernel.get_and_update_in`

  ## Examples

      iex> Indifferent.get_and_update_in(%{"a" => %{"x" => 1}}, [:a, :x], fn x -> {x * 2, x * 4} end)
      {2, %{"a" => %{"x" => 4}}}

      iex> Indifferent.get_and_update_in(%{"a" => %{"x" => 1}}, [:a, :y], fn nil -> {2, 4} end)
      {2, %{"a" => %{:y => 4, "x" => 1}}}

  """
  def get_and_update_in(data, keys, updater),
  do: Kernel.get_and_update_in(access(data), keys, updater) |>
  fn {a, b} -> {unwrap(a), unwrap(b)} end.()


  @doc ~S"""
  Auto wrap version of `Kernel.pop_in`

  ## Examples

      iex> Indifferent.pop_in(%{"a" => 1}, [:a])
      {1, %{}}
  """
  def pop_in(data, keys),
  do: Kernel.pop_in(access(data), keys) |>
  fn {a, b} -> {unwrap(a), unwrap(b)} end.()

end
