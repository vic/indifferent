defmodule IndifferentTest do
  use ExUnit.Case

  import Indifferent.Sigils

  defmodule User do
    defstruct name: "john"
  end


  doctest Indifferent
  doctest Indifferent.Access
  doctest Indifferent.README
  doctest Indifferent.Sigils
end
