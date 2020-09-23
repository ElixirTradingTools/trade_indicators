defmodule TradeIndicators.Tests.ATR do
  use ExUnit.Case
  alias TradeIndicators.Util, as: U
  alias TradeIndicators.ATR
  alias Enum, as: E

  @msft_data TradeIndicators.Tests.Fixtures.get(:msft_m1_2020_07_27)
  @tr [0.21, 0.18, 0.31, 0.15, 0.20, 0.15, 0.28, 0.20, 0.19, 0.17] ++
        [0.23, 0.37, 0.21, 0.16, 0.29, 0.15, 0.42, 0.27, 0.11, 0.23] ++
        [0.41, 0.63, 0.25, 0.43, 0.68, 0.48, 0.56, 0.56, 0.42, 0.68] ++
        [1.25, 0.40, 0.69, 0.09, 0.15, 0.21, 0.14, 0.08, 1.35, 0.00]
  @wma_atr [0.21, 0.21, 0.22, 0.21, 0.22, 0.22, 0.23, 0.23, 0.24, 0.25] ++
             [0.27, 0.28, 0.28, 0.30, 0.33, 0.34, 0.38, 0.39, 0.42, 0.48] ++
             [0.52, 0.54, 0.52, 0.55, 0.55, 0.53, 0.53, 0.00, 0.00, 0.00] ++
             [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]
  @ema_atr [0.23, 0.23, 0.24, 0.23, 0.24, 0.25, 0.27, 0.26, 0.27, 0.29] ++
             [0.30, 0.31, 0.31, 0.32, 0.34, 0.35, 0.38, 0.38, 0.40, 0.44] ++
             [0.47, 0.48, 0.46, 0.49, 0.50, 0.47, 0.47, 0.00, 0.00, 0.00] ++
             [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]

  describe "ATR" do
    test "true range calculations and weighted moving average" do
      U.context(fn ->
        atr_list =
          @msft_data
          |> Enum.reduce({%ATR{method: :wma}, []}, fn bar, {state, bars} ->
            bars = [bar | bars]
            {ATR.step(state, bars), bars}
          end)
          |> case do
            {%{list: atr_list}, _} -> atr_list
          end

        tr_results = E.map(atr_list, fn %{tr: v} -> U.rnd(v) end)
        assert tr_results == @tr

        atr_results = E.map(atr_list, fn %{avg: v} -> U.rnd(v) end)
        assert atr_results == @wma_atr
      end)
    end

    test "exponential moving average" do
      U.context(fn ->
        atr_list =
          @msft_data
          |> Enum.reduce({%ATR{method: :ema}, []}, fn bar, {state, bars} ->
            bars = [bar | bars]
            {ATR.step(state, bars), bars}
          end)
          |> case do
            {%{list: atr_list}, _} -> atr_list
          end

        atr_results =
          E.map(atr_list, fn
            %{avg: nil} -> 0.0
            %{avg: v} -> U.rnd(v)
          end)

        assert @ema_atr == atr_results
      end)
    end
  end
end
