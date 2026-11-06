defmodule Test do
  # def test(foo, bar) do
  def test(foo, bar) do
    test_var = 1234
    IO.puts(test_var)
  end

  defp priv_test do
    :ok
  end
end

defprotocol MyProto do
  def my_func(a)
end

defmacro my_macro(a, b) do
  :ok
end

defdelegate my_delegated_func(a), to: String

defguard is_my_guard(a) when is_atom(a)
