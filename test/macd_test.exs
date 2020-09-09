defmodule Tests.MACD do
  use ExUnit.Case
  alias Indicators.MACD
  alias TradeIndicators.Util, as: U
  alias Decimal, as: D
  alias Enum, as: E

  @msft_data Tests.Fixtures.fixture(:msft_m1_2020_07_27)
  @histogram [0.06, 0.06, 0.06, 0.06, 0.03, 0.01, -0.01]
  @signal [0.13, 0.14, 0.16, 0.17, 0.18, 0.18, 0.18]
  @macd [0.12, 0.10, 0.10, 0.11, 0.12, 0.12, 0.14, 0.16, 0.19, 0.20, 0.22, 0.23, 0.22, 0.19, 0.17]

  describe "MACD" do
    test "sma/3" do
      list = for(i <- 1..3, do: %{a: i})
      assert nil == MACD.sma({:a, list}, 4)
      assert MACD.sma({:a, list}, 3) |> D.eq?(2)
    end

    test "get_avg/3" do
      nil_list = for(_ <- 1..5, do: %{a: nil})
      num_list = for(i <- 1..5, do: %{a: i})

      assert MACD.get_avg({:a, nil_list}, nil, 5) == nil
      assert MACD.get_avg({:a, nil_list}, nil, 5) == nil
      assert MACD.get_avg({:a, num_list}, nil, 5) == D.new(3)

      list = for(i <- 1..11, do: %{a: i})
      assert MACD.get_avg({:a, list}, nil, 12) == nil

      list = for(i <- 1..12, do: %{a: i})
      assert MACD.get_avg({:a, list}, nil, 12) == D.from_float(6.5)
    end

    test "values on MSFT 2020/07/31" do
      U.context(fn ->
        {%{list: macd_list}, _} =
          @msft_data
          |> E.reduce({%Indicators.MACD{}, []}, fn bar, {state, bars} ->
            bars = bars ++ [bar]
            state = MACD.step(state, bars)
            {state, bars}
          end)

        n1 = E.at(macd_list, 0)
        n11 = E.at(macd_list, 10)
        n12 = E.at(macd_list, 11)
        n25 = E.at(macd_list, 24)
        n26 = E.at(macd_list, 25)
        n33 = E.at(macd_list, 32)
        n34 = E.at(macd_list, 33)
        n40 = E.at(macd_list, 39)
        assert match?(%{ema1: nil, ema2: nil, macd: nil, his: nil, sig: nil}, n1)
        assert match?(%{ema1: nil, ema2: nil, macd: nil, his: nil, sig: nil}, n11)
        assert match?(%{ema1: %D{}, ema2: nil, macd: nil, his: nil, sig: nil}, n12)
        assert match?(%{ema1: %D{}, ema2: nil, macd: nil, his: nil, sig: nil}, n25)
        assert match?(%{ema1: %D{}, ema2: %D{}, macd: %D{}, his: nil, sig: nil}, n26)
        assert match?(%{ema1: %D{}, ema2: %D{}, macd: %D{}, his: nil, sig: nil}, n33)
        assert match?(%{ema1: %D{}, ema2: %D{}, macd: %D{}, his: %D{}, sig: %D{}}, n34)
        assert match?(%{ema1: %D{}, ema2: %D{}, macd: %D{}, his: %D{}, sig: %D{}}, n40)

        {macd_result, histogram_result, signal_result} =
          macd_list
          |> E.reduce({[], [], []}, fn %{macd: m, his: h, sig: s}, {a, b, c} ->
            a = if(is_nil(m), do: a, else: a ++ [U.rnd(m)])
            b = if(is_nil(h), do: b, else: b ++ [U.rnd(h)])
            c = if(is_nil(s), do: c, else: c ++ [U.rnd(s)])
            {a, b, c}
          end)

        assert @macd == macd_result
        assert @histogram == histogram_result
        assert @signal == signal_result
      end)
    end
  end
end
