defmodule Indifferent.Transform do


  def key_id(x, _indifferent), do: {:ok, x}

  def key_to_string(x, _i) do
    try do
      {:ok, to_string(x)}
    rescue
      _ -> :error
    end
  end

  def key_to_existing_atom(x, i) do
    case key_to_string(x, i) do
      {:ok, str} ->
        try do
          {:ok, String.to_existing_atom(str)}
        rescue
          _ -> :error
        end
      _ -> :error
    end
  end

  def key_to_int(x, i) do
    case key_to_string(x, i) do
      {:ok, str} ->
        try do
          {:ok, String.to_integer(str)}
        rescue
          _ -> :error
        end
      _ -> :error
    end
  end

  def value_id(value, _indifferent), do: {:ok, value}

  def value_enum_to_indifferent(value, indifferent = %Indifferent.Access{}) do
    cond do
      is_map(value) or is_list(value) or is_tuple(value) ->
        {:ok, Indifferent.wrap(value, indifferent)}
      :else ->
        :error
    end
  end

end
