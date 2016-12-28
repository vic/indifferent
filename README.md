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
      [{:indifferent, "~> 0.8"}]
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

### Indifferent module


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
# `get_in/2`, `get_and_update_in/3`, `pop_in/2`
iex> Indifferent.get_and_update_in(%{"a" => %{"x" => 1}}, [:a, :x], fn x -> {x * 2, x * 4} end)
{2, %{"a" => %{"x" => 4}}}


##
# Indifferent `path/2` lets you use any syntax you want for
# accessing the nested value you need.
iex> %{"b" => %{"c" => %{"d" => %{"e" => 4}}}} |> Indifferent.path(b["c"][:d].e)
4

##
# And works on lists, tuples, keywords
iex> [9, %{"c" => {:ok, [e: 4]}}] |> Indifferent.path(1.c["1"].e)
4

##
# Accessing nil yields nil
iex> nil |> Indifferent.path(foo.bar)
nil

##
# Can access inside structs
iex> %User{name: "john"} |> Indifferent.path(name)
"john"

##
# And can be used with Kernel methods.
iex> Kernel.get_in(%{"a" => {0, 2}}, Indifferent.path(a["1"]))
2

##
# `path/2` can also take a Keyword of paths and returns a keyword of values
iex> %{"b" => [1, 2]} |> Indifferent.path(x: b[-1])
[x: 2]

##
# The `read/1` macro is a convenience that reads an indifferent path on the first value
iex> System.put_env("COLOR", "red")
iex> Indifferent.read(System.get_env.COLOR)
"red"

##
# Just like `path/2`, the `read/1` macro can also take a Keyword of named things to read
iex> System.put_env("COLOR", "red")
iex> Process.put(:color, "blue")
iex> Indifferent.read(a: System.get_env.COLOR, b: Process.get.color)
[a: "red", b: "blue"]

```

### Indifferent sigils

The `~i` and `~I` sigils are shortcuts for the API
previously described.

```elixir
iex> import Indifferent.Sigils
Indifferent.Sigils

##
# `~i` is the sigil for `Indifferent.read/1`
iex> data = %{"a" => [b: {10, 20}]}
iex> ~i(data.a.b[1])
20

# When piped a value it will act just like `Indifferent.path/2`
iex> data = %{"a" => [b: {10, 20}]}
iex> data |> ~i(a.b[1])
20


##
# `~I` is the sigil version of `Indifferent.path/1`
# for use with Kernel access functions.

iex> data = %{"a" => [b: {10, 20}]}
iex> Kernel.get_in(data, ~I(a.b[1]))
20

iex> data = %{"a" => [b: {10, 20}]}
iex> Kernel.pop_in(data, ~I(a.b))
{{10, 20}, %{"a" => []}}

```

