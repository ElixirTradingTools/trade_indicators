defmodule TradeIndicators.ATR do
  use TypedStruct
  alias __MODULE__, as: ATR
  alias __MODULE__.Item
  alias TradeIndicators.MA
  alias TradeIndicators.Util, as: U
  alias Decimal, as: D
  alias Enum, as: E
  alias Map, as: M

  typedstruct do
    field :list, List.t(), default: []
    field :period, pos_integer(), default: 14
    field :method, :ema | :wma, default: :ema
  end

  typedstruct module: Item do
    field :avg, D.t() | nil, default: nil
    field :tr, D.t() | nil, default: nil
    field :t, non_neg_integer()
  end

  @zero D.new(0)

  def step(chart = %ATR{list: atr_list, period: period, method: method}, bars)
      when is_list(bars) and is_list(atr_list) and is_integer(period) and period > 1 do
    ts =
      case bars do
        [%{t: t} | _] -> t
        _ -> nil
      end

    case length(bars) do
      0 ->
        chart

      n when n < period ->
        new_atr = %{avg: nil, t: ts, tr: E.take(bars, 2) |> get_tr()}
        %{chart | list: [new_atr | atr_list]}

      _ ->
        new_atr = E.take(bars, 2) |> get_tr() |> get_atr(atr_list, period, ts, method)
        %{chart | list: [new_atr | atr_list]}
    end
  end

  def get_tr([%{c: c, h: h, l: l}]), do: get_tr(c, h, l)
  def get_tr([%{h: h, l: l}, %{c: c}]), do: get_tr(c, h, l)

  def get_tr(c, h, l)
      when (is_binary(c) or is_integer(c)) and
             (is_binary(h) or is_integer(h)) and
             (is_binary(l) or is_integer(l)),
      do: get_tr(D.new(c), D.new(h), D.new(l))

  def get_tr(c = %D{}, h = %D{}, l = %D{}) do
    D.sub(h, l)
    |> D.max(D.abs(D.sub(h, c)))
    |> D.max(D.abs(D.sub(l, c)))
  end

  def make_tr_list(new_tr, atr_list, period) do
    atr_list
    |> E.take(period - 1)
    |> E.map(fn %{tr: v} -> v || @zero end)
    |> case do
      list -> [new_tr | list]
    end
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
      |> case do
        list -> [new_tr | list]
      end
      |> E.reduce(@zero, fn n, t -> D.add(t, U.dec(n)) end)
      |> D.div(period)
    else
      atr_list
      |> hd()
      |> M.get(:avg)
      |> case do
        last_tr -> MA.ema({last_tr, new_tr}, period)
      end
    end
  end
end
