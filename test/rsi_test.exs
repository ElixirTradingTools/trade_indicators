defmodule TradeIndicators.Tests.RSI do
  use ExUnit.Case
  alias TradeIndicators.Util, as: U
  alias TradeIndicators.RSI
  alias Enum, as: E

  @msft_data TradeIndicators.Tests.Fixtures.fixture(:msft_m1_2020_08_17)
  @expected_rsi_values [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] ++
                         [62.22, 65.01, 52.65, 52.29, 57.78, 60.82, 61.77, 56.71, 57.19, 54.02] ++
                         [55.95, 52.50, 53.65, 56.50, 60.02, 63.08, 62.81, 62.52, 62.21, 66.50] ++
                         [71.07, 71.07, 69.65, 72.06]

  describe "RSI" do
    test "step/2" do
      U.context(fn ->
        {%{list: rsi_list}, _} =
          @msft_data
          |> E.reduce({%RSI{}, []}, fn bar, {state, bars} ->
            bars = bars ++ [bar]
            state = RSI.step(state, bars)
            {state, bars}
          end)

        result_rsi = for %{value: rsi} <- rsi_list, do: U.rnd(rsi)

        assert @expected_rsi_values == result_rsi
      end)
    end
  end
end
