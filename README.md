# DualMap
  A DualMap is simply a dual-entry map struct that allows you to reference pairs of data using both, a key or a value. In a DualMap you can look up a value from its key or a key from its value.

  In simple terms we could say that a DualMap is a map where there is no difference between key and value, both can be either one or the other.

  ## How does it work?

  A DualMap actually stores 2 maps, a direct one with the key => value pairs, and a reverse one with the value => key pairs. At the same time it also stores metadata about the names (ids) of the datas (called master keys).

  To create a new DualMap you must use the `DualMap.new` function. You must pass to it a pair of names that will be the identifiers of the master keys.

  ```elixir
  DualMap.new({:hostname, :ip})
  ```

  The order of the master keys is important. If you later want to make insertions into the DualMap and you use the `DualMap.put_ordered` function the value pairs will assume that they are ordered as defined at the time of creating the DualMap with `DualMap.new`.

  ## Let's see some examples:

  ```elixir
  iex> dm = DualMap.new({:hostname, :ip})
  []
  iex> DualMap.put_ordered(dm, [
    {"ns3", "192.168.0.4"},
    {"ns2", "192.168.0.3"},
    {"ns1", "192.168.0.2"}
  ])
  [
    {"ns1", "192.168.0.2"},
    {"ns2", "192.168.0.3"},
    {"ns3", "192.168.0.4"}
  ]
  iex> DualMap.delete(dm, :ip, "192.168.0.3")
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
    {:dual_map, "~> 0.1.0"}
  ]
end
```

