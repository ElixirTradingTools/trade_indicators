defmodule TradeIndicators.MACD do
  use TypedStruct
  alias __MODULE__, as: MACD
  alias TradeIndicators.MA
  alias TradeIndicators.Util, as: U
  alias Decimal, as: D
  alias Enum, as: E
  alias List, as: L
  alias Map, as: M

  typedstruct do
    field :list, List.t(), default: []
    field :chart_len, pos_integer(), default: 1_000
    field :ema1_len, pos_integer(), default: 12
    field :ema2_len, pos_integer(), default: 26
    field :ema3_len, pos_integer(), default: 9
  end

  typedstruct module: Item do
    field :ema1, D.t() | nil
    field :ema2, D.t() | nil
    field :macd, D.t() | nil
    field :sig, D.t() | nil
    field :his, D.t() | nil
    field :t, non_neg_integer()
  end

  defp get_prev_macd([]), do: {nil, nil, nil}

  defp get_prev_macd([last | _]) do
    case last do
      %Item{ema1: a, ema2: b, sig: c} -> {a, b, c}
    end
  end

  def sma({key, src_list}, len) when is_list(src_list) and is_integer(len) do
    case E.take(src_list, len) do
      subset ->
        case {length(subset), L.last(subset), subset} do
          {l, _, _} when l < len -> nil
          {_, %{^key => nil}, _} -> nil
          {_, _, subset} -> subset |> E.reduce(0, &D.add(M.get(&1, key), &2)) |> D.div(len)
        end
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
        sma({key, [%{key => latest} | src_list]}, len)

      {{_, _, latest = %D{}}, avg_prev = %D{}, len}
      when is_integer(len) ->
        MA.ema({avg_prev, latest}, len)

      {{key, src_list}, avg_prev = %D{}, len}
      when is_list(src_list) and is_integer(len) and is_atom(key) ->
        MA.ema({avg_prev, L.first(src_list)[key]}, len)
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

    new_macd_map = %Item{
      ema1: new_ema12_pt,
      ema2: new_ema26_pt,
      macd: new_macd_line_pt,
      sig: new_signal_pt,
      his: new_histogram_pt,
      t: L.first(bars)[:t]
    }

    %{macd_container | list: E.take([new_macd_map | macd_list], max_len)}
  end
end
