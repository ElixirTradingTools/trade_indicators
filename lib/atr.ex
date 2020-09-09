defmodule Indicators.ATR.Item do
  defstruct avg: nil,
            tr: nil,
            t: nil
end

defmodule Indicators.ATR do
  alias Indicators.ATR.Item
  alias Indicators.MA
  alias TradeIndicators.Util, as: U
  alias Decimal, as: D
  alias List, as: L
  alias Enum, as: E
  alias Map, as: M

  @zero D.new(0)

  defstruct list: [],
            period: 14,
            method: :ema

  def step(chart = %{list: atr_list, period: period, method: method}, bars)
      when is_list(bars) and is_list(atr_list) and is_integer(period) and period > 1 do
    ts = L.last(bars)[:t] || 0

    case length(bars) do
      0 ->
        chart

      n when n < period ->
        new_atr = %{avg: nil, t: ts, tr: E.take(bars, -2) |> get_tr()}
        %{chart | list: atr_list ++ [new_atr]}

      _ ->
        new_atr = E.take(bars, -2) |> get_tr() |> get_atr(atr_list, period, ts, method)
        %{chart | list: atr_list ++ [new_atr]}
    end
  end

  def get_tr([%{c: c, h: h, l: l}]), do: get_tr(c, h, l)
  def get_tr([%{c: c}, %{h: h, l: l}]), do: get_tr(c, h, l)

  def get_tr(c = %D{}, h = %D{}, l = %D{}) do
    D.sub(h, l)
    |> D.max(D.abs(D.sub(h, c)))
    |> D.max(D.abs(D.sub(l, c)))
  end

  def make_tr_list(new_tr, atr_list, period) do
    atr_list
    |> E.take(-(period - 1))
    |> E.map(fn %{tr: v} -> v || @zero end)
    |> E.concat([new_tr])
  end

  def get_atr(new_tr, atr_list, period, ts, avg_fn) when avg_fn in [:wma, :ema] do
    %Item{
      avg: get_avg(atr_list, new_tr, period, avg_fn),
      tr: new_tr,
      t: ts
    }
  end

  def get_avg(atr_list, new_tr, period, :wma) do
    new_tr
    |> make_tr_list(atr_list, period)
    |> MA.wma(period)
  end

  def get_avg(atr_list, new_tr, period, :ema) do
    if length(atr_list) == period - 1 do
      atr_list
      |> E.map(fn %{tr: tr} -> tr end)
      |> E.concat([new_tr])
      |> E.reduce(@zero, fn n, t -> D.add(t, U.dec(n)) end)
      |> D.div(period)
    else
      atr_list
      |> L.last()
      |> M.get(:avg)
      |> (fn last_tr -> {last_tr, new_tr} end).()
      |> MA.ema(period)
    end
  end
end
