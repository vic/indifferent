defmodule IndifferentTest do
  use ExUnit.Case
  defmodule User do
    defstruct name: "john"
  end
  doctest Indifferent
  doctest Indifferent.Access
  doctest Indifferent.README
end
