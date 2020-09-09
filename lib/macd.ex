defmodule Indicators.MACD do
  alias Indicators.MACD
  alias Indicators.MA
  alias TradeIndicators.Util, as: U
  alias Decimal, as: D
  alias Enum, as: E
  alias List, as: L

  defstruct list: [],
            chart_len: 1_000,
            ema1_len: 12,
            ema2_len: 26,
            ema3_len: 9

  defp get_prev_macd(macd_list) when is_list(macd_list) do
    case L.last(macd_list) do
      nil -> {nil, nil, nil}
      %{ema1: a, ema2: b, sig: c} -> {a, b, c}
    end
  end

  def sma({key, src_list}, len) when is_list(src_list) and is_integer(len) do
    tail = E.take(src_list, -len)

    case {length(tail), L.first(tail), tail} do
      {l, _, _} when l < len -> nil
      {_, %{^key => nil}, _} -> nil
      {_, _, tail} -> tail |> E.reduce(0, &D.add(&1[key], &2)) |> D.div(len)
    end
  end

  def get_avg(tuple, avg_prev, len) do
    case {tuple, avg_prev, len} do
      {{_, [], _}, _, _} ->
        nil

      {{_, _, nil}, nil, _} ->
        nil

      {{key, src_list}, nil, len}
      when is_list(src_list) and is_integer(len) and is_atom(key) ->
        sma({key, src_list}, len)

      {{key, src_list, latest = %D{}}, nil, len}
      when is_list(src_list) and is_integer(len) and is_atom(key) ->
        sma({key, src_list ++ [%{key => latest}]}, len)

      {{_, _, latest = %D{}}, avg_prev = %D{}, len}
      when is_integer(len) ->
        MA.ema({avg_prev, latest}, len)

      {{key, src_list}, avg_prev = %D{}, len}
      when is_list(src_list) and is_integer(len) and is_atom(key) ->
        MA.ema({avg_prev, L.last(src_list)[key]}, len)
    end
  end

  defp dif(nil, _), do: nil
  defp dif(_, nil), do: nil
  defp dif(a, b), do: D.sub(U.dec(a), U.dec(b))

  def step(
        macd_container = %MACD{
          list: macd_list,
          chart_len: max_len,
          ema1_len: len1,
          ema2_len: len2,
          ema3_len: len3
        },
        bars
      )
      when is_list(bars) do
    {ema12_prev, ema26_prev, signal_prev} = get_prev_macd(macd_list)
    new_ema12_pt = get_avg({:c, bars}, ema12_prev, len1)
    new_ema26_pt = get_avg({:c, bars}, ema26_prev, len2)
    new_macd_line_pt = dif(new_ema12_pt, new_ema26_pt)
    new_signal_pt = get_avg({:macd, macd_list, new_macd_line_pt}, signal_prev, len3)
    new_histogram_pt = dif(new_macd_line_pt, new_signal_pt)

    new_macd_map = %{
      ema1: new_ema12_pt,
      ema2: new_ema26_pt,
      macd: new_macd_line_pt,
      sig: new_signal_pt,
      his: new_histogram_pt,
      t: L.last(bars)[:t]
    }

    %{macd_container | list: E.take(macd_list ++ [new_macd_map], -max_len)}
  end
end
