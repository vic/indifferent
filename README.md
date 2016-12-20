# Indifferent
[![Build Status](https://travis-ci.org/vic/indifferent.svg?branch=master)](https://travis-ci.org/vic/indifferent)

This library provides a wrapper for indifferent access on maps, structs, lists and tuples.

You could use Indifferent to wrap a parameters hash or something without having to distingish
on the type of keys (atoms or binaries) akin to the features of Rails' HashWithIndifferentAccess.

## Installation

[Available in Hex](https://hex.pm/packages/indifferent), the package can be installed as:

  1. Add `indifferent` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:indifferent, "~> 0.2"}]
    end
    ```

  2. Ensure `indifferent` is started before your application:

    ```elixir
    def application do
      [applications: [:indifferent]]
    end
    ```

## Usage

Be sure to look at the [documentation](https://hexdocs.pm/indifferent) for more examples.

```elixir

##
# Wrapping a map and accesing it with an atom key
iex> i = Indifferent.access(%{"a" => 1})
iex> i[:a]
1


##
# You can provide your custom list of key transformations
# and specify how are keys indifferents for your use case.
iex> i = Indifferent.access(%{"a" => 1},
...>   key_transforms: [fn x, _indifferent -> {:ok, String.downcase(x)} end])
iex> i["A"]
1

##
# Indifferent is compatible with Elixir's Access
iex> Kernel.get_in(%{"a" => 1}, [Indifferent.at(:a)])
1
iex> Kernel.get_in(Indifferent.access(%{"a" => 1}), [:a])
1

##
# Or you can auto wrap data by using Indifferent's version of
# `get_in`, `get_and_update_in`, `pop`
iex> Indifferent.get_and_update_in(%{"a" => %{"x" => 1}}, [:a, :x], fn x -> {x * 2, x * 4} end)
{2, %{"a" => %{"x" => 4}}}


##
# Indifferent `path` lets you use any syntax you want for
# accessing the nested value you need.
iex> %{"b" => %{"c" => %{"d" => %{"e" => 4}}}} |> Indifferent.path(b["c"][:d].e)
4

##
# And works on lists and tuples
iex> [9, %{"c" => {:ok, %{"e" => 4}}}] |> Indifferent.path(1.c["1"].e)
4


##
# And can be used with Kernel methods.
iex> Kernel.get_in(%{"a" => {0, 1}}, Indifferent.path(a["1"]))
1
```
