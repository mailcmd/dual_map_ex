defmodule DualMap.WCN do
  @moduledoc """
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
  """

  defstruct [
    __data: %{},
    __master_keys_map: %{},
    __ordered_master_keys: []
  ]

  @typedoc "DualMap.WCN struct"
  @type t :: %__MODULE__{}

  @doc """
  Returns an empty DualMap.WCN struct. The order of the master keys are important for posterior operations with the struct.

  ## Examples

      iex> DualMap.WCN.new({:hostname, :ip})
      []
  """
  @spec new(master_keys :: {master_key1 :: any(), master_key2 :: any()}) :: t()
  def new({master_key1, master_key2}) do
    %DualMap.WCN{
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
  Returns a DualMap.WCN struct initialized with the values indicated in the second argument. As the `new/1` function, the order of the master keys are important for posterior operations with the struct.

  ## Examples

      # Initializing with one pair of values
      iex> DualMap.WCN.new({:hostname, :ip}, {"ns1", "192.168.0.2"})
      [{"ns1", "192.168.0.2"}]

      # Initializing with more than one pair of values
      iex> DualMap.WCN.new({:hostname, :ip}, [
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
  Delete one or more pairs of datas and returns the DualMap.WCN without that pairs. The pairs are found looking for `key` in the the internal map indexed by `master_key`.

  ## Examples

      iex> dm = DualMap.WCN.new({:hostname, :ip}, [
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

      iex> DualMap.WCN.delete(dm, :ip, ["192.168.0.3", "192.168.0.2"])
      [{"ns3", "192.168.0.4"}]
  """
  @spec delete(t(), master_key :: any(), keys :: any()) :: t()
  def delete(dual_map, master_key, list) when is_list(list), do:
    drop(dual_map, master_key, list)
  def delete(dual_map, master_key, key) do
    case dual_map.__data[master_key][key] do
      key2 when not is_nil(key2) ->
        master_key2 = dual_map.__master_keys_map[master_key]
        map_key1 = Map.delete(dual_map.__data[master_key], key)
        map_key2 = Map.delete(dual_map.__data[master_key2], key2)
        data = %{dual_map.__data |
          master_key => map_key1,
          master_key2 => map_key2
        }
        %{dual_map | __data: data}

      _ ->
        dual_map
    end
  end

  defp drop(dual_map, master_key1, list) do
    list
      |> Enum.reduce(dual_map, fn (key, dm) ->
        delete(dm, master_key1, key)
      end)
  end

  @doc """
  Insert or replace one or more pairs of datas in a DualMap.WCN struc. If the third parameters is a list of tuples, every one is inserted/replaced in the DualMap.WCN secuentialy. With this function you need pass the a master_key to indicate which value of the tuple will be interpreted as key and which one as value.

  ## Examples

      iex> dm = DualMap.WCN.new({:hostname, :ip})
      []

      # Inserting/replacing many
      iex> DualMap.WCN.put(dm, :ip, [
        {"192.168.0.4", "ns3"},
        {"192.168.0.3", "ns2"},
        {"192.168.0.2", "ns1"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      Or inserting just one
      iex> DualMap.WCN.put(dm, :ip, {"192.168.0.4", "ns3"})
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
  This function is similar to `put/3` but you does not need to pass a master key because the function will assume that you are sending the keys and values in the same order as you defined when you created the DualMap.WCN with `new/1` or `new/2`.

  ## Examples
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
  Returns the value asociated to `key` taking the internal map indexed by `master_key`. If `key` does not exists in the map, `default` or `nil` is returned.

  ## Examples

      iex> dm = DualMap.WCN.new({:hostname, :ip}, [
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]
      iex> DualMap.WCN.get(dm, :ip, "192.168.0.4")
      "ns3"

      iex> DualMap.WCN.get(dm, :hostname, "ns3")
      "192.168.0.4"
  """
  @spec get(t(), master_key :: any(), key :: any(), default :: any()) :: any()
  def get(dual_map, master_key, key, default \\ nil) do
    Map.get(dual_map.__data[master_key], key, default)
  end

  @doc """
  Return the complete internal map indexed by `master_key`.

  ## Examples

      iex> dm = DualMap.WCN.new({:hostname, :ip}, [
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.WCN.get_map(dm, :hostname)
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
  Return a list with all the keys of the internal map indexed by `master_key`.

  ## Examples

      iex> dm = DualMap.WCN.new({:hostname, :ip}, [
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])

      iex> DualMap.WCN.keys(dm, :hostname)
      ["ns1", "ns2", "ns3"]
  """
  @spec keys(t(), master_key :: any()) :: list()
  def keys(dual_map, master_key) do
    Map.keys(dual_map.__data[master_key])
  end

  @doc """
  Return a list with all the values of the internal map indexed by `master_key`.

  ## Examples

      iex> dm = DualMap.WCN.new({:hostname, :ip}, [
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.WCN.values(dm, :hostname)
      ["192.168.0.2", "192.168.0.3", "192.168.0.4"]
  """
  @spec values(t(), master_key :: any()) :: list()
  def values(dual_map, master_key) do
    Map.values(dual_map.__data[master_key])
  end

  @doc """
  Return a list of the pairs `{key, value}` taking the map indexed by the first master_key defined with `new/1` or `new/2`. This function is used by `inspect` to print the DualMap.WCN.

  If you also pass an option `:pairs_inverted`, the list will have the pairs with key/value inverted because will take the internal map indexed by the second master_key defined with `new/1` or `new/2`.
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
  Just as `get/4` but do not accept default parameter. If the key exists, will return the tuple `{:ok, value}` and if not `:error`.

  ## Examples

      iex> dm = DualMap.WCN.new({:hostname, :ip}, [
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])

      iex> DualMap.WCN.fetch(dm, :ip, "192.168.0.4")
      {:ok, "ns3"}

      iex> DualMap.WCN.fetch(dm, :ip, "192.168.0.6")
      :error
  """
  @spec fetch(t(), any(), any()) :: {:ok, any()} | :error
  def fetch(dual_map, master_key, key) do
    Map.fetch(dual_map.__data[master_key], key)
  end

  @doc """
  Work equals to `fetch/3` but erroring out if key doesn't exists.
  """
  @spec fetch!(t(), any(), any()) :: any()
  def fetch!(dual_map, master_key, key) do
    Map.fetch!(dual_map.__data[master_key], key)
  end

  @doc """
  Checks if two DualMap.WCNs are equal.

  Two maps are considered to be equal if both internal maps contains the same keys and values.
  """
  @spec equal?(t(), t()) :: boolean()
  def equal?(dual_map1, dual_map2), do:
    dual_map1 == dual_map2

  @doc """
  Return de size of the DualMap.WCN counting the number of pairs.
  """
  @spec count(t()) :: pos_integer()
  def count(dual_map) do
    [master_key, _] = dual_map.__ordered_master_keys
    map_size(dual_map.__data[master_key])
  end

  @doc """
  Checks if `key` exists within DualMap.WCN.

  ## Examples

      iex> dm = DualMap.WCN.new({:hostname, :ip}, [
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.WCN.has?(dm, "192.168.0.4")
      true

      iex> DualMap.WCN.has?(dm, "ns2")
      true

      iex> DualMap.WCN.has?(dm, "ns5")
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
  Checks if the pair `key_value` (tuple size 2) exists within DualMap.WCN either as key => value or as value => key.

  ## Examples

      iex> dm = DualMap.WCN.new({:hostname, :ip}, [
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.WCN.member?(dm, {"192.168.0.4", "ns3"})
      true

      iex> DualMap.WCN.member?(dm, {"ns3", "192.168.0.4"})
      true

      iex> DualMap.WCN.member?(dm, {"ns1", "192.168.0.4"})
      false
  """
  @spec member?(t(), key_value :: {any(), any()}) :: boolean()
  def member?(dual_map, {key, value}) do
    [master_key1, master_key2] = dual_map.__ordered_master_keys
    match?(%{^key => ^value}, dual_map.__data[master_key1])
      or
    match?(%{^key => ^value}, dual_map.__data[master_key2])
  end

end

defimpl Inspect, for: DualMap.WCN do
  import Inspect.Algebra
  def inspect(dual_map, opts) do
    to_doc(DualMap.WCN.to_list(dual_map), opts)
  end
end
