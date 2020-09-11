defmodule TradeIndicators.MA do
  alias TradeIndicators.Util, as: U
  alias Decimal, as: D
  alias Enum, as: E

  @zero D.new(0)

  def safe_at(list, n) do
    case E.at(list, n) do
      nil -> @zero
      num when is_float(num) -> D.from_float(num)
      num when is_integer(num) -> D.new(num)
      num = %D{} -> num
    end
  end

  def rma(prev = %D{}, next = %D{}, num) when is_integer(num) and num > 1,
    do: D.add(next, D.mult(num - 1, prev)) |> D.div(num)

  def ema({prev, next}, num, factor \\ :"2/(N+1)")
      when is_integer(num) and next != nil and factor in [:"2/(N+1)", :"1/N"] do
    factor_a =
      case factor do
        :"2/(N+1)" -> D.div(2, D.add(num, 1))
        :"1/N" -> D.div(1, num)
      end

    factor_b = D.sub(1, factor_a)
    D.add(D.mult(U.dec(next), factor_a), D.mult(U.dec(prev || 0), factor_b))
  end

  def wma(series, period)
      when is_list(series) and length(series) > 0 and is_integer(period) and period > 1 do
    series =
      case period - length(series) do
        0 -> series
        n when n < period -> for(_ <- 1..n, do: 0) ++ series
        _ -> E.take(series, -period)
      end

    n_sum =
      for i <- 1..period, reduce: 0 do
        t -> D.mult(safe_at(series, i - 1), i) |> D.add(t)
      end

    D.div(n_sum, D.mult(period, D.div(D.add(period, 1), 2)))
  end
end
