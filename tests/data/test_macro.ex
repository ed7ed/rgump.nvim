defmodule TestMacro do
  defmacro my_macro(a, b) do
    quote do
      unquote(a) + unquote(b)
    end
  end

  defmacrop priv_macro(a) do
    quote do: unquote(a)
  end
end
