# DualMap
A DualMap is simply a dual-entry map struct that allows you to reference pairs of data using both, a key or a value. In a DualMap you can look up a value from its key or a key from its value.

In simple terms we could say that a DualMap is a map where there is no difference between key and value, both can be either one or the other.

## How does it work?

A DualMap actually stores 2 maps, a direct one with the key => value pairs, and a inverted one with the value => key pairs.

To create a new DualMap you must use the `DualMap.new` function.

```elixir
DualMap.new()
```

## Let's see some examples:

```elixir
iex> dm = DualMap.new({:hostname})
[]
iex> DualMap.put(dm, [
  {"ns3", "192.168.0.4"},
  {"ns2", "192.168.0.3"},
  {"ns1", "192.168.0.2"}
])
[
  {"ns1", "192.168.0.2"},
  {"ns2", "192.168.0.3"},
  {"ns3", "192.168.0.4"}
]
iex> DualMap.delete(dm, "192.168.0.3")
[
  {"ns1", "192.168.0.2"},
  {"ns3", "192.168.0.4"}
]
```

# DualMap.WCL 

A DualMap.WCN is like a DualMap but with column names. So you need to reference columns (called master keys) in most of the calls.

## How does it work?

A DualMap.WCN, as a DualMap stores 2 maps, (a direct and an inverted one), but at the same time it also stores metadata about the column names of the datas (called master keys).

To create a new DualMap.WCN you must use the `DualMap.WCN.new` function. You must pass to it a pair of names that will be the names of the columns.

```elixir
DualMap.WCN.new({:hostname, :ip})
```

The order of the master keys is important. If you later want to make insertions into the DualMap.WCN and you use the `DualMap.WCN.put_ordered` function the value pairs will assume that they are ordered as defined at the time of creating the DualMap.WCN with `DualMap.WCN.new`.

## Let's see some examples:

```elixir
iex> dm = DualMap.WCN.new({:hostname, :ip})
[]
iex> DualMap.WCN.put_ordered(dm, [
  {"ns3", "192.168.0.4"},
  {"ns2", "192.168.0.3"},
  {"ns1", "192.168.0.2"}
])
[
  {"ns1", "192.168.0.2"},
  {"ns2", "192.168.0.3"},
  {"ns3", "192.168.0.4"}
]
iex> DualMap.WCN.delete(dm, :ip, "192.168.0.3")
[
  {"ns1", "192.168.0.2"},
  {"ns3", "192.168.0.4"}
]
```


## Full docs

For full documentation follow the link [doc](https://hexdocs.pm/dual_map_ex/)

## Installation

```elixir
def deps do
  [
    {:dual_map_ex, "~> 0.1.0"}
  ]
end
```

