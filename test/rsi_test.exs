defmodule TradeIndicators.Tests.RSI do
  use ExUnit.Case
  alias TradeIndicators.Util, as: U
  alias TradeIndicators.RSI
  alias Enum, as: E

  @rsi_expected [72.06, 69.65, 71.07, 71.07, 66.50, 62.21, 62.52, 62.81, 63.08, 60.02] ++
                  [56.50, 53.65, 52.50, 55.95, 54.02, 57.19, 56.71, 61.77, 60.82, 57.78] ++
                  [52.29, 52.65, 65.01, 62.22, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] ++
                  [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  @msft_data TradeIndicators.Tests.Fixtures.get(:msft_m1_2020_08_17)

  describe "RSI" do
    test "step/2" do
      U.context(fn ->
        result_list =
          E.reduce(@msft_data, {%RSI{}, []}, fn bar, {state, bars} ->
            bars = [bar | bars]
            {RSI.step(state, bars), bars}
          end)
          |> case do
            {%{list: list}, _} -> E.map(list, fn %{value: v} -> U.rnd(v) end)
          end

        assert @rsi_expected == result_list
      end)
    end
  end
end
