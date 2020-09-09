defmodule Indicators.RSI.Item do
  defstruct value: nil,
            avg_gain: nil,
            avg_loss: nil,
            gain: nil,
            loss: nil,
            t: 0
end

defmodule Indicators.RSI do
  alias Indicators.RSI
  alias Indicators.MA
  alias TradeIndicators.Util, as: U
  alias Indicators.RSI.Item
  alias Decimal, as: D
  alias Enum, as: E

  defstruct list: [],
            period: 14

  @zero D.new(0)
  @one_hundred D.new(100)

  def step(chart = %RSI{}, bars) when is_list(bars) do
    case length(bars) do
      0 -> chart
      1 -> update_rsi_list(chart, bars)
      _ -> update_rsi_list(chart, E.take(bars, -2))
    end
  end

  def update_rsi_list(rsi_chart = %RSI{list: []}, [%{t: ts}]),
    do: %{rsi_chart | list: [new_rsi_struct({nil, nil, nil}, @zero, @zero, ts)]}

  def update_rsi_list(
        rsi_chart = %RSI{list: rsi_list, period: len},
        [%{c: close_old}, %{c: close_new, t: ts}]
      )
      when is_list(rsi_list) do
    delta = D.sub(close_new, close_old)
    gain_now = delta |> D.max(0)
    loss_now = delta |> D.min(0) |> D.abs()

    new_rsi_item =
      case length(rsi_list) do
        l when l < len -> {nil, nil, nil}
        ^len -> get_initial_gain_loss(rsi_list, {gain_now, loss_now}, len) |> calc_rsi()
        _ -> calc_rs(rsi_list, gain_now, loss_now, len) |> calc_rsi()
      end
      |> new_rsi_struct(gain_now, loss_now, ts)

    %{rsi_chart | list: rsi_list ++ [new_rsi_item]}
  end

  def new_rsi_struct({rsi, avg_g, avg_l}, gain, loss, ts),
    do: %Item{value: rsi, avg_gain: avg_g, avg_loss: avg_l, gain: gain, loss: loss, t: ts}

  def calc_rs(rsi_list, gain_now, loss_now, len) do
    %Item{avg_gain: gain_last, avg_loss: loss_last} = E.at(rsi_list, -1)
    {MA.rma(gain_last, gain_now, len), MA.rma(loss_last, loss_now, len)}
  end

  def calc_rsi({avg_gain = %D{}, avg_loss = %D{}}) do
    cond do
      D.eq?(@zero, avg_loss) -> {@one_hundred, avg_gain, avg_loss}
      D.eq?(@zero, avg_gain) -> {@zero, avg_gain, avg_loss}
      true -> {D.sub(100, D.div(100, D.add(1, D.div(avg_gain, avg_loss)))), avg_gain, avg_loss}
    end
  end

  def get_initial_gain_loss(rsi_list, {gain_now, loss_now}, period)
      when is_list(rsi_list) and is_integer(period) and period > 1 do
    E.reduce(rsi_list, {0, 0}, fn %{gain: gain, loss: loss}, {total_gain, total_loss} ->
      {D.add(total_gain, U.dec(gain)), D.add(total_loss, U.dec(loss))}
    end)
    |> (fn {g, l} -> {D.div(D.add(g, gain_now), period), D.div(D.add(l, loss_now), period)} end).()
  end
end
