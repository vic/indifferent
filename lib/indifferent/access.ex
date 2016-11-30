defmodule Indifferent.Access do

  @behaviour Access

  @default_key_transforms [
    &Indifferent.Transform.key_id/2,
    &Indifferent.Transform.key_to_string/2,
    &Indifferent.Transform.key_to_int/2,
    &Indifferent.Transform.key_to_existing_atom/2
  ]

  @default_value_transforms [
    &Indifferent.Transform.value_enum_to_indifferent/2,
    &Indifferent.Transform.value_id/2
  ]

  defstruct on: nil, key_transforms: @default_key_transforms, value_transforms: @default_value_transforms

  @doc ~S"""
  Fetch an indifferent key.

  ## Examples

      iex> Indifferent.Access.fetch(%{"a" => 1}, :a)
      {:ok, 1}

      iex> Indifferent.Access.fetch(%{"a" => 1}, :b)
      :error

  """
  def fetch(on, key)

  def fetch(on = %__MODULE__{on: data}, key),
  do: Kernel.get_in(data, [fn_fetch(on, key)])
  def fetch(data, key),
  do: fetch(Indifferent.access(data), key)


  @doc ~S"""
  Get the value under an indifferent key

  ## Examples

      iex> Indifferent.Access.get(%{"a" => 1}, :a)
      1

      iex> Indifferent.Access.get(%{a: 1}, "a")
      1

      iex> Indifferent.Access.get(%{a: 1}, "a")
      1
  """
  def get(on, key), do: get(on, key, nil)

  def get(on = %__MODULE__{on: data}, key, default),
  do: Kernel.get_in(data, [fn_get(on, key, default)])
  def get(data, key, default),
  do: get(Indifferent.access(data), key, default)


  @doc ~S"""
  Get and update a value under an indifferent key

  ## Examples

      iex> Indifferent.Access.get_and_update(%{a: 1}, "a", fn x -> {x * 2, x * 4} end)
      {2, %{a: 4}}

  """
  def get_and_update(on, key, updater)

  def get_and_update(on = %__MODULE__{on: data}, key, updater),
  do: Kernel.get_and_update_in(data, [fn_get_and_update(on, key)], updater)
  def get_and_update(data, key, updater),
  do: get_and_update(Indifferent.access(data), key, updater)

  @doc ~S"""
  Pop the value under an indifferent key

  ## Examples

      iex> Indifferent.Access.pop(%{a: 1}, "a")
      {1, %{}}
  """
  def pop(on, key)

  def pop(on = %__MODULE__{on: data}, key),
  do: Kernel.pop_in(data, [fn_get_and_update(on, key)])
  def pop(data, key),
  do: pop(Indifferent.access(data), key)


  def at(key) do
    fn
      :get, data, next ->
        fn_get(Indifferent.access(data), key, nil).(:get, Indifferent.unwrap(data), next)
      :get_and_update, data, next ->
        fn_get_and_update(Indifferent.access(data), key).(:get_and_update, Indifferent.unwrap(data), next)
    end
  end

  defp fn_fetch(on, key) do
    fn :get, data, next ->
      with({_key, getter} <- key_getter(on, data, key)) do
        {:ok, getter.() |> value_transform(on)}
      else
        _ -> :error
      end |> next.()
    end
  end

  defp fn_get(on, key, default) do
    fn :get, data, next ->
      with({_key, getter} <- key_getter(on, data, key)) do
        getter.() |> value_transform(on)
      else
        _ -> default
      end |> next.()
    end
  end

  defp fn_get_and_update(on, key) do
    fn :get_and_update, data, next ->
      {key, value} =
        with({key, getter} <- key_getter(on, data, key)) do
          {key, getter.()}
        else
          _ -> {key, nil}
        end

      setter = Indifferent.Accessor.setter(data, key)

      value
      |> value_transform(on)
      |> next.()
      |> fn
        {got, update} ->
          {got, update} = {value_transform(got, on), Indifferent.unwrap(update)}
          {got, setter.(update)}
        :pop ->
          popper = Indifferent.Accessor.popper(data, key)
          popper.()
      end.()
    end
  end

  defp key_getter(on, data, indifferent_key) do
    on.key_transforms
    |> Stream.map(fn key_transform -> key_transform.(indifferent_key, on) end)
    |> Stream.map(fn
      {:ok, key} ->
        Indifferent.Accessor.key?(data, key) && {key, Indifferent.Accessor.getter(data, key)}
      _ ->
        nil
    end)
    |> Stream.filter(fn x -> x end)
    |> Stream.take(1)
    |> Enum.to_list
    |> fn [first] -> first; _ -> :error end.()
  end

  defp value_transform(value, indifferent) do
    indifferent.value_transforms
    |> Stream.map(fn value_transform -> value_transform.(value, indifferent) end)
    |> Stream.filter(fn {:ok, _} -> true; _ -> false end)
    |> Stream.take(1)
    |> Enum.to_list
    |> fn [{:ok, first}] -> first; _ -> value end.()
  end

end
