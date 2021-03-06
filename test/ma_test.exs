defmodule TradeIndicators.Tests.MovingAverage do
  use ExUnit.Case
  alias TradeIndicators.Util, as: U
  alias TradeIndicators.MA
  alias Decimal, as: D

  @fixture [0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  test "linear weighted average" do
    U.context(fn ->
      assert @fixture |> MA.wma(14) |> U.rnd() == 0.07

      assert MA.wma([3], 14) |> D.to_float() == 0.4
      assert MA.wma([2, 2, 1], 5) |> D.to_float() == 1.4
      assert MA.wma([0, 4, 3, 2, 1], 5) |> D.to_float() == 2.0
    end)
  end
end
