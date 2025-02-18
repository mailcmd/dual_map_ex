defmodule DualMap do
  @moduledoc """

  A DualMap is simply a dual-entry map struct that allows you to reference pairs of data using both, a key or a value. In a DualMap you can look up a value from its key or a key from its value.

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
  """

  defstruct [
    __data: %{},
    __master_keys_map: %{},
    __ordered_master_keys: []
  ]

  @typedoc "DualMap struct"
  @type t :: %__MODULE__{}

  @doc """
  Returns an empty DualMap struct. The order of the master keys are important for posterior operations with the struct.

  ## Examples

      iex> dm = DualMap.new({:hostname, :ip})
      []
  """
  @spec new(master_keys :: {master_key1 :: any(), master_key2 :: any()}) :: t()
  def new({master_key1, master_key2}) do
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

  @doc """
  Returns a DualMap struct initialized with the values indicated in the second argument. As the `new/1` function, the order of the master keys are important for posterior operations with the struct.

  ## Examples

      # Initializing with one pair of values
      iex> DualMap.new({:hostname, :ip}, {"ns1", "192.168.0.2"})
      [{"ns1", "192.168.0.2"}]

      # Initializing with more than one pair of values
      iex> DualMap.new({:hostname, :ip}, [
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]
  """
  @spec new({master_key1 :: any(), master_key2 :: any()}, {any(), any()} | list(tuple())) :: t()
  def new({_, _} = master_keys, values) when is_tuple(values) or is_list(values) do
    new(master_keys)
    |> put_ordered(values)
  end

  @doc """
  Delete a pair of datas and returns the DualMap without that pair. The pair is found looking for `key1` (third parameter) in the the map that has as master key the `master_key1` (second parameter) as key.

  ## Examples

      iex> dm = DualMap.new({:hostname, :ip}, [
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
  """
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

  @doc """
  Just the same that `[delete/3](#delete/3)` but you can pass a list of keys to delete.

  ## Examples

      iex> dm = DualMap.new({:hostname, :ip}, [
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.drop(dm, :ip, ["192.168.0.3", "192.168.0.2"])
      [{"ns3", "192.168.0.4"}]
  """
  @spec drop(t(), master_key1 :: any(), list()) :: t()
  def drop(dual_map, master_key1, list) do
    list
      |> Enum.reduce(dual_map, fn (key, dm) ->
        delete(dm, master_key1, key)
      end)
  end

  @doc """
  Insert or replace one or more pairs of datas in a DualMap. If the third parameters is a list of tuples, every one is inserted/replaced in the DualMap secuentialy. With this function you need pass the the master_key to indicate which value of the tuple will be interpreted as key and which one as value.

  ## Examples

      iex> dm = DualMap.new({:hostname, :ip})
      []

      # Inserting/replacing many
      iex> DualMap.put(dm, :ip, [
        {"192.168.0.4", "ns3"},
        {"192.168.0.3", "ns2"},
        {"192.168.0.2", "ns1"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      # Or inserting just one
      iex> DualMap.put(dm, :ip, {"192.168.0.4", "ns3"})
      [{"ns3", "192.168.0.4"}]
  """
  @spec put(t(), master_key :: any(), {key :: any(), value :: any()} | list(tuple())) :: t()
  def put(dual_map, _, []), do: dual_map
  def put(dual_map, master_key1, [{key, value} | rest]) do
    dual_map = put(dual_map, master_key1, {key, value})
    put(dual_map, master_key1, rest)
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

  @doc """
  This function is similar to `[put/3](#put/3)` but you does not need pass a master key because the function will assume that you are sending the keys and values in the same order as you specified when you created the DualMap with `[new/1](#new/1)` or `[new/2](#new/2)`.

  ## Examples
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
  """
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

  @doc """
  Returns the value asociated to `key` taking the map indexed by `master_key`. If `key` does not exists in the map, `default` or `nil` is returned.

  ## Examples

      iex> dm = DualMap.put(dm, :ip, [
        {"192.168.0.4", "ns3"},
        {"192.168.0.3", "ns2"},
        {"192.168.0.2", "ns1"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.get(dm, :ip, "192.168.0.4")
      "ns3"
  """
  @spec get(t(), master_key :: any(), key :: any(), default :: any()) :: any()
  def get(dual_map, master_key, key, default \\ nil) do
    Map.get(dual_map.__data[master_key], key, default)
  end

  @doc """
  Return the complete map indexed by `master_key`.

  ## Examples

      iex> dm = DualMap.put(dm, :ip, [
        {"192.168.0.4", "ns3"},
        {"192.168.0.3", "ns2"},
        {"192.168.0.2", "ns1"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.get_map(dm, :hostname)
      %{
        "ns1" => "192.168.0.2",
        "ns2" => "192.168.0.3",
        "ns3" => "192.168.0.4"
      }
  """
  @spec get_map(t(), master_key :: any()) :: map()
  def get_map(dual_map, master_key) do
    Map.fetch!(dual_map.__data, master_key)
  end

  @doc """
  Return a list with all the keys of the map indexed by `master_key`.

  ## Examples

      iex> dm = DualMap.put(dm, :ip, [
        {"192.168.0.4", "ns3"},
        {"192.168.0.3", "ns2"},
        {"192.168.0.2", "ns1"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.keys(dm, :hostname)
      ["ns1", "ns2", "ns3"]
  """
  @spec keys(t(), master_key :: any()) :: list()
  def keys(dual_map, master_key) do
    Map.keys(dual_map.__data[master_key])
  end

  @doc """
  Return a list with all the values of the map indexed by `master_key`.

  ## Examples

      iex> dm = DualMap.put(dm, :ip, [
        {"192.168.0.4", "ns3"},
        {"192.168.0.3", "ns2"},
        {"192.168.0.2", "ns1"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.values(dm, :hostname)
      ["192.168.0.2", "192.168.0.3", "192.168.0.4"]
  """
  @spec values(t(), master_key :: any()) :: list()
  def values(dual_map, master_key) do
    Map.values(dual_map.__data[master_key])
  end

  @doc """
  Return a list of the pairs `{key, value}` taking the map indexed by the first master_key defined with `[new/1](#new/1)` or `[new/2](#new/2)`. This function is used by `inspect` to print the struct.

  If you pass as option `:pairs_inverted` the list will have the pairs with key/value inverted because will take the map indexed by the second master_key defined with `[new/1](#new/1)` or `[new/2](#new/2)`.
  """
  @spec to_list(t()) :: [{any(), any()}]
  def to_list(dual_map, option \\ nil)
  def to_list(dual_map, nil) do
    [master_key, _] = dual_map.__ordered_master_keys
    Map.to_list(dual_map.__data[master_key])
  end
  def to_list(dual_map, :pairs_inverted) do
    [_, master_key] = dual_map.__ordered_master_keys
    Map.to_list(dual_map.__data[master_key])
  end

  @doc """
  Just as `[get](#get/4)` but do not accept default parameter. If the key exists, will return the tuple `{:ok, value}` and if not `:error`.

  ## Examples

      iex> dm = DualMap.put(dm, :ip, [
        {"192.168.0.4", "ns3"},
        {"192.168.0.3", "ns2"},
        {"192.168.0.2", "ns1"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.fetch(dm, :ip, "192.168.0.4")
      {:ok, "ns3"}

      iex> DualMap.fetch(dm, :ip, "192.168.0.6")
      :error
  """
  @spec fetch(t(), any(), any()) :: {:ok, any()} | :error
  def fetch(dual_map, master_key, key) do
    Map.fetch(dual_map.__data[master_key], key)
  end

  @doc """
  Work equals to `[fetch/3](#fetch/3)` but erroring out if key doesn't exists.
  """
  @spec fetch!(t(), any(), any()) :: any()
  def fetch!(dual_map, master_key, key) do
    Map.fetch!(dual_map.__data[master_key], key)
  end

  @doc """
  Checks if two DualMaps are equal.

  Two maps are considered to be equal if they contain the same keys and those keys contain the same values.
  """
  @spec equal?(t(), t()) :: boolean()
  def equal?(dual_map1, dual_map2), do: Map.equal?(dual_map1, dual_map2)

  @doc """
  Return de size of the DualMap counting the number of pairs.
  """
  @spec count(t()) :: pos_integer()
  def count(dual_map) do
    [master_key, _] = dual_map.__ordered_master_keys
    map_size(dual_map.__data[master_key])
  end

  @doc """
  Checks if `key` exists within DualMap.

  ## Examples

      iex> dm = DualMap.put(dm, :ip, [
        {"192.168.0.4", "ns3"},
        {"192.168.0.3", "ns2"},
        {"192.168.0.2", "ns1"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.has?(dm, "192.168.0.4")
      true

      iex> DualMap.has?(dm, "ns2")
      true

      iex> DualMap.has?(dm, "ns5")
      false
  """
  @spec has?(t(), key :: any()) :: boolean()
  def has?(dual_map, key_value) do
    [master_key1, master_key2] = dual_map.__ordered_master_keys
    match?(%{^key_value => _}, dual_map.__data[master_key1])
      or
    match?(%{^key_value => _}, dual_map.__data[master_key2])
  end

  @doc """
  Checks if the `pair` tuple of key/value exists within DualMap either as key => value or as value => key.

  ## Examples

      iex> dm = DualMap.put(dm, :ip, [
        {"192.168.0.4", "ns3"},
        {"192.168.0.3", "ns2"},
        {"192.168.0.2", "ns1"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.member?(dm, {"192.168.0.4", "ns3"})
      true

      iex> DualMap.member?(dm, {"ns3", "192.168.0.4"})
      true

      iex> DualMap.member?(dm, {"ns1", "192.168.0.4"})
      false
  """
  @spec member?(t(), pair :: {any(), any()}) :: boolean()
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
