# Trade Indicators

Feedback and contributions are welcome.

Unit tests are passing. Please refer to the tests to see how these are used.

Each indicator is a state machine. Use the respective module struct for initial
state. OHLC chart data is a list and each new bar is appended before passing it
into the indicator `step/2` function. The indicator must be run once each time a
new bar is appended. In the tests, you can see how to use `Enum.reduce/3` to run
the indicator on your chart data.


## Installation

Not currently available in Hex. Please reference this repo to install:

```elixir
def deps do
  [
    {
      :trade_indicators,
      git: "https://github.com/rm-rf-etc/trade-indicators.git",
      tag: "0.1.1"
    }
  ]
end
```
