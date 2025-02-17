defmodule DualMap do
  @moduledoc """
  # DualMap
  A DualMap is simply a dual-entry map that allows you to reference pairs of data using both a key or a value. In a DualMap you can look up a value from its key or a key from its value.

  In simple terms we could say that a DualMap is a map where there is no difference between key and value, both can be either one or the other.

  ## How does it work?

  A DualMap actually stores 2 maps, a direct one with the key => value pairs, and a reverse one with the value => key pairs. At the same time it also stores metadata about the names (ids) of the datas (called master keys).

  To create a new DualMap you must use the `DualMap.new` function. You must pass to it a pair of names that will be the identifiers of the master keys.

  ```elixir
  DualMap.new(:hostname, :ip)
  ```

  The order of the master keys is important. If you later want to make insertions into the DualMap and you use the `DualMap.put_ordered` function the value pairs will assume that they are ordered as defined at the time of creating the DualMap with `DualMap.new`.

  ## Let's see some examples:

  ```elixir
  iex> dm = DualMap.new(:hostname, :ip)
  []
  iex> DualMap.put_ordered(dm, [{"ns3", "192.168.0.4"}, {"ns2", "192.168.0.3"}, {"ns1", "192.168.0.2"}])
  [{"ns1", "192.168.0.2"}, {"ns2", "192.168.0.3"}, {"ns3", "192.168.0.4"}]
  iex> DualMap.delete(dm, :ip, "192.168.0.3")
  [{"ns1", "192.168.0.2"}, {"ns3", "192.168.0.4"}]
  ```
  """

  defstruct [
    __data: %{},
    __master_keys_map: %{},
    __ordered_master_keys: []
  ]

  @typedoc "DualMap"
  @type t :: %DualMap{}

  @spec new({master_key1 :: any(), master_key2 :: any()}) :: t()
  def new({master_key1, master_key2}), do: new(master_key1, master_key2)

  @spec new(master_key1 :: any(), master_key2 :: any()) :: t()
  def new(master_key1, master_key2) do
    %DualMap{
      __data: %{
        master_key1 => %{},
        master_key2 => %{},
      },
      __master_keys_map: %{
        master_key1 => master_key2,
        master_key2 => master_key1
      },
      __ordered_master_keys: [master_key1, master_key2]
    }
  end

  @spec delete(t(), master_key1 :: any(), key1 :: any()) :: t()
  def delete(dual_map, master_key1, key1) do
    case dual_map.__data[master_key1][key1] do
      key2 when not is_nil(key2) ->
        master_key2 = dual_map.__master_keys_map[master_key1]
        map_key1 = Map.delete(dual_map.__data[master_key1], key1)
        map_key2 = Map.delete(dual_map.__data[master_key2], key2)
        data = %{dual_map.__data |
          master_key1 => map_key1,
          master_key2 => map_key2
        }
        %{dual_map | __data: data}

      _ ->
        dual_map
    end
  end

  @spec drop(t(), master_key1 :: any(), list()) :: t()
  def drop(dual_map, master_key1, list) do
    list
      |> Enum.reduce(dual_map, fn (key, dm) ->
        delete(dm, master_key1, key)
      end)
  end

  def put(dual_map, master_key1, {key, value}) do
    master_key2 = dual_map.__master_keys_map[master_key1]
    map_key1 = Map.put(dual_map.__data[master_key1], key, value)
    map_key2 = Map.put(dual_map.__data[master_key2], value, key)
    data = %{dual_map.__data |
      master_key1 => map_key1,
      master_key2 => map_key2
    }
    %{dual_map | __data: data}

  end

  @spec put_ordered(t(), {any(), any()} | list(tuple())) :: t()
  def put_ordered(dual_map, {_, _} = pair) do
    [master_key1, _] = dual_map.__ordered_master_keys
    put(dual_map, master_key1, pair)
  end
  def put_ordered(dual_map, []), do: dual_map
  def put_ordered(dual_map, [pair | rest]) do
    dual_map = put_ordered(dual_map, pair)
    put_ordered(dual_map, rest)
  end

  @spec put_ordered(t(), any(), any()) :: t()
  def put_ordered(dual_map, value1, value2) do
    put_ordered(dual_map, {value1, value2})
  end

  @spec get(t(), any(), any(), any()) :: any()
  def get(dual_map, master_key, key, default \\ nil) do
    Map.get(dual_map.__data[master_key], key, default)
  end

  @spec get_map(t(), any()) :: map()
  def get_map(dual_map, master_key) do
    Map.fetch!(dual_map.__data, master_key)
  end

  @spec keys(t(), any()) :: list()
  def keys(dual_map, master_key) do
    Map.keys(dual_map.__data[master_key])
  end

  @spec values(t(), any()) :: list()
  def values(dual_map, master_key) do
    Map.values(dual_map.__data[master_key])
  end

  @spec to_list(t()) :: [{any(), any()}]
  def to_list(dual_map, option \\ nil)
  def to_list(dual_map, nil) do
    [master_key, _] = dual_map.__ordered_master_keys
    Map.to_list(dual_map.__data[master_key])
  end
  def to_list(dual_map, :pair_inverted) do
    [_, master_key] = dual_map.__ordered_master_keys
    Map.to_list(dual_map.__data[master_key])
  end

  @spec fetch(t(), any(), any()) :: {:ok, any()} | :error
  def fetch(dual_map, master_key, key) do
    Map.fetch(dual_map.__data[master_key], key)
  end

  @spec fetch!(t(), any(), any()) :: any()
  def fetch!(dual_map, master_key, key) do
    Map.fetch!(dual_map.__data[master_key], key)
  end

  @spec equal?(t(), t()) :: boolean()
  def equal?(dual_map1, dual_map2), do: Map.equal?(dual_map1, dual_map2)

  @spec count(t()) :: pos_integer()
  def count(dual_map) do
    [master_key, _] = dual_map.__ordered_master_keys
    map_size(dual_map.__data[master_key])
  end

  @spec has?(t(), any()) :: boolean()
  def has?(dual_map, key_value) do
    [master_key1, master_key2] = dual_map.__ordered_master_keys
    match?(%{^key_value => _}, dual_map.__data[master_key1])
      or
    match?(%{^key_value => _}, dual_map.__data[master_key2])
  end

  @spec member?(t(), {any(), any()}) :: boolean()
  def member?(dual_map, {key, value}) do
    [master_key1, master_key2] = dual_map.__ordered_master_keys
    match?(%{^key => ^value}, dual_map.__data[master_key1])
      or
    match?(%{^key => ^value}, dual_map.__data[master_key2])
  end

end

defimpl Inspect, for: DualMap do
  import Inspect.Algebra
  def inspect(dual_map, opts) do
    to_doc(DualMap.to_list(dual_map), opts)
  end
end

# defimpl Inspect, for: DualMap do
#   def inspect(dual_map, opts) do
#     to_doc(DualMap.to_list(dual_map), opts)
#   end
# end
