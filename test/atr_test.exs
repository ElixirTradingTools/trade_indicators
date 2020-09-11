defmodule TradeIndicators.Tests.ATR do
  use ExUnit.Case
  alias TradeIndicators.Util, as: U
  alias TradeIndicators.ATR
  alias Enum, as: E

  @msft_data TradeIndicators.Tests.Fixtures.fixture(:msft_m1_2020_07_27)
  @tr [0.00, 1.35, 0.08, 0.14, 0.21, 0.15, 0.09, 0.69, 0.40, 1.25] ++
        [0.68, 0.42, 0.56, 0.56, 0.48, 0.68, 0.43, 0.25, 0.63, 0.41] ++
        [0.23, 0.11, 0.27, 0.42, 0.15, 0.29, 0.16, 0.21, 0.37, 0.23] ++
        [0.17, 0.19, 0.20, 0.28, 0.15, 0.20, 0.15, 0.31, 0.18, 0.21]
  @wma_atr [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00] ++
             [0.00, 0.00, 0.00, 0.53, 0.53, 0.55, 0.55, 0.52, 0.54, 0.52] ++
             [0.48, 0.42, 0.39, 0.38, 0.34, 0.33, 0.30, 0.28, 0.28, 0.27] ++
             [0.25, 0.24, 0.23, 0.23, 0.22, 0.22, 0.21, 0.22, 0.21, 0.21]
  @ema_atr [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00] ++
             [0.00, 0.00, 0.00, 0.47, 0.47, 0.50, 0.49, 0.46, 0.48, 0.47] ++
             [0.44, 0.40, 0.38, 0.38, 0.35, 0.34, 0.32, 0.31, 0.31, 0.30] ++
             [0.29, 0.27, 0.26, 0.27, 0.25, 0.24, 0.23, 0.24, 0.23, 0.23]

  describe "ATR" do
    test "true range calculations and weighted moving average" do
      U.context(fn ->
        {%{list: atr_list}, _} =
          @msft_data
          |> Enum.reduce({%ATR{method: :wma}, []}, fn bar, {state, bars} ->
            bars = bars ++ [bar]
            state = ATR.step(state, bars)
            {state, bars}
          end)

        tr_results = E.map(atr_list, fn %{tr: v} -> U.rnd(v) end)
        assert tr_results == @tr

        atr_results = E.map(atr_list, fn %{avg: v} -> U.rnd(v) end)
        assert atr_results == @wma_atr
      end)
    end

    test "exponential moving average" do
      U.context(fn ->
        {%{list: atr_list}, _} =
          @msft_data
          |> Enum.reduce({%ATR{method: :ema}, []}, fn bar, {state, bars} ->
            bars = bars ++ [bar]
            state = ATR.step(state, bars)
            {state, bars}
          end)

        atr_results =
          atr_list
          |> E.map(fn
            %{avg: nil} -> 0.0
            %{avg: v} -> U.rnd(v)
          end)

        assert @ema_atr == atr_results
      end)
    end
  end
end
