defmodule TradeIndicators.Util do
  alias Decimal, as: D
  alias Enum, as: E

  @zero D.new(0)

  def rnd(val),
    do: dec(val) |> D.round(2, :half_even) |> D.to_float()

  def dec(num) do
    case num do
      nil -> @zero
      num = %D{} -> num
      num when is_integer(num) -> D.new(num)
      num when is_float(num) -> D.from_float(num)
    end
  end

  def decimals(some_map) when is_map(some_map) do
    some_map
    |> E.map(fn {k, v} -> {k, dec(v)} end)
    |> Map.new()
  end

  def context(func) when is_function(func),
    do: D.Context.with(%D.Context{precision: 8, rounding: :half_even}, func)
end
