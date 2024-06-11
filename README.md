# Ports

**TODO: Add description**

## Installation

[Available in Hex](https://hex.pm/packages/ports), the package can be installed
by adding `ports` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ports, "~> 0.1"}
  ]
end
```

## Updating

1. Download the UNLOCODE csv from [UNECE](https://unece.org/trade/cefact/UNLOCODE-Download)
2. If there are multiple csv files, compile them into one and save it to `priv/data/code-list.csv`
