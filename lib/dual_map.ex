defmodule DualMap do
  @moduledoc """
  A DualMap is simply a dual-entry map struct that allows you to reference pairs of data using both, a key or a value. In a DualMap you can look up a value from its key or a key from its value.

  In simple terms we could say that a DualMap is a map where there is no difference between key and value, both can be either one or the other.

  ## How does it work?

  A DualMap actually stores 2 maps, a direct one with the key => value pairs, and a inveted one with the value => key pairs.

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
  """

  defstruct [
    __data: %{},
    __master_keys_map: %{},
    __ordered_master_keys: []
  ]

  @typedoc "DualMap struct"
  @type t :: %__MODULE__{}

  @doc """
  Returns an empty DualMap struct.

  ## Examples

      iex> DualMap.new({:hostname})
      []
  """
  @spec new() :: t()
  def new() do
    %DualMap{
      __data: %{
        map1: %{},
        map2: %{},
      }
    }
  end

  @doc """
  Returns a DualMap struct initialized with the values indicated in the second argument. As the `new/1` function, the order of the master keys are important for posterior operations with the struct.

  ## Examples

      # Initializing with one pair of values
      iex> DualMap.new({"ns1", "192.168.0.2"})
      [{"ns1", "192.168.0.2"}]

      # Initializing with more than one pair of values
      iex> DualMap.new([
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
  @spec new({any(), any()} | list(tuple())) :: t()
  def new(values) when is_tuple(values) or is_list(values) do
    new()
    |> put(values)
  end

  @doc """
  Delete one or many pair of datas and returns the DualMap without that pairs. The pair is found looking for `key` both internal maps, so that it is possible to reference the pair both by its key and by its value.

  ## Examples

      iex> dm = DualMap.new([
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

      # Or if you want to delete many...
      iex> DualMap.delete(dm, ["ns2", "192.168.0.2"])
      [{"ns3", "192.168.0.4"}]
  """
  @spec delete(t(), keys :: any() | list()) :: t()
  def delete(dual_map, [key | keys])  do
    dual_map = _delete(dual_map, key)
    delete(dual_map, keys)
  end
  def delete(dual_map, key), do: _delete(dual_map, key)

  defp _delete(dual_map, key)  do
    {key1, key2} =
      case {dual_map.__data.map1[key], dual_map.__data.map2[key]} do
        {nil, nil} -> {nil, nil}
        {key2, nil} -> {key, key2}
        {nil, key1} -> {key1, key}
      end

    data = %{dual_map.__data |
      map1:  Map.delete(dual_map.__data.map1, key1),
      map2: Map.delete(dual_map.__data.map2, key2)
    }
    %{dual_map | __data: data}

  end

  @doc """
  Insert or replace one or more pairs of datas in a DualMap.

  ## Examples

      iex> dm = DualMap.new()
      []

      # Inserting/replacing many
      iex> DualMap.put(dm, [
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
      iex> DualMap.put(dm, {"192.168.0.4", "ns3"})
      [{"ns3", "192.168.0.4"}]
  """
  @spec put(t(), {key :: any(), value :: any()} | list(tuple())) :: t()
  def put(dual_map, []), do: dual_map
  def put(dual_map, [{key, value} | rest]) do
    dual_map = put(dual_map, {key, value})
    put(dual_map, rest)
  end
  def put(dual_map, {key, value}) do
    map_key1 = Map.put(dual_map.__data.map1, key, value)
    map_key2 = Map.put(dual_map.__data.map2, value, key)
    data = %{dual_map.__data |
      map1: map_key1,
      map2: map_key2
    }
    %{dual_map | __data: data}
  end

  @doc """
  Returns the value asociated to `key` in any of the internal maps. If `key` does not exists, `default` or `nil` is returned.

  ## Examples

      iex> dm = DualMap.new([
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.get(dm, "192.168.0.4")
      "ns3"

      iex> DualMap.get(dm, "ns3")
      "192.168.0.4"
  """
  @spec get(t(), key :: any(), default :: any()) :: any()
  def get(dual_map, key, default \\ nil) do
    case Map.get(dual_map.__data.map1, key) do
      nil -> Map.get(dual_map.__data.map2, key, default)
      value -> value
    end
  end

  @doc """
  Return the complete directed or inverted internal map.

  ## Examples

      iex> dm = DualMap.new([
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.get_map(dm)
      %{
        "ns1" => "192.168.0.2",
        "ns2" => "192.168.0.3",
        "ns3" => "192.168.0.4"
      }

      iex> DualMap.get_map(dm, :inverted)
      %{
        "192.168.0.2" => "ns1",
        "192.168.0.3" => "ns2",
        "192.168.0.4" => "ns3"
      }

  """
  @spec get_map(t(), opts :: (:inverted | nil)) :: map()
  def get_map(dual_map, opts \\ nil)
  def get_map(dual_map, :inverted) do
    dual_map.__data.map2
  end
  def get_map(dual_map, _) do
    dual_map.__data.map1
  end

  @doc """
  Return a list with all the keys of the directed or inverted internal map.

  ## Examples

      iex> dm = DualMap.new([
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])

      iex> DualMap.keys(dm)
      ["ns1", "ns2", "ns3"]

      iex> DualMap.keys(dm, :inverted)
      ["192.168.0.2", "192.168.0.3", "192.168.0.4"]
  """
  @spec keys(t(), opts :: (:inverted | nil)) :: list()
  def keys(dual_map, opts \\ nil)
  def keys(dual_map, :inverted) do
    Map.keys(dual_map.__data.map2)
  end
  def keys(dual_map, _) do
    Map.keys(dual_map.__data.map1)
  end

  @doc """
  Return a list with all the values of the directed or inverted internal map.

  ## Examples

      iex> dm = DualMap.new([
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])
      [
        {"ns1", "192.168.0.2"},
        {"ns2", "192.168.0.3"},
        {"ns3", "192.168.0.4"}
      ]

      iex> DualMap.values(dm)
      ["192.168.0.2", "192.168.0.3", "192.168.0.4"]

      iex> DualMap.values(dm, :inverted)
      ["ns1", "ns2", "ns3"]

  """
  @spec values(t(), opts :: (:inverted | nil)) :: list()
  def values(dual_map, opts \\ nil)
  def values(dual_map, :inverted) do
    Map.values(dual_map.__data.map2)
  end
  def values(dual_map, _) do
    Map.values(dual_map.__data.map1)
  end

  @doc """
  Return a list of the pairs `{key, value}` taking the directed internal map. This function is used by `inspect` to print the DualMap.

  If you also pass the option `:pairs_inverted`, the list returned will have the pairs with key/value taking de inverted internal map.
  """
  @spec to_list(t()) :: [{any(), any()}]
  def to_list(dual_map, option \\ nil)
  def to_list(dual_map, :pairs_inverted) do
    Map.to_list(dual_map.__data.map2)
  end
  def to_list(dual_map, _) do
    Map.to_list(dual_map.__data.map1)
  end

  @doc """
  Just as `get/3` but do not accept default parameter. If the key exists in any of the internal maps, will return the tuple `{:ok, value}`, if not will return `:error`.

  ## Examples

      iex> dm = DualMap.new([
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
      ])

      iex> DualMap.fetch(dm, "192.168.0.4")
      {:ok, "ns3"}

      iex> DualMap.fetch(dm, "ns3")
      {:ok, "192.168.0.4"}

      iex> DualMap.fetch(dm, "192.168.0.6")
      :error
  """
  @spec fetch(t(), any()) :: {:ok, any()} | :error
  def fetch(dual_map, key) do
    case Map.fetch(dual_map.__data.map1, key) do
      {:ok, _} = return -> return
      :error -> Map.fetch(dual_map.__data.map2, key)
    end
  end

  @doc """
  Work equals to `fetch/3` but return a value (as `get/3`) or erroring out if key doesn't exists.
  """
  @spec fetch!(t(), any()) :: any()
  def fetch!(dual_map, key) do
    case Map.fetch(dual_map.__data.map1, key) do
      :error -> Map.fetch!(dual_map.__data.map2, key)
      return -> return
    end
  end

  @doc """
  Checks if two DualMaps are equal.

  Two maps are considered to be equal if both internal maps contains the same keys and values.
  """
  @spec equal?(t(), t()) :: boolean()
  def equal?(dual_map1, dual_map2), do:
    dual_map1 == dual_map2

  @doc """
  Return de size of the DualMap counting the number of pairs.
  """
  @spec count(t()) :: pos_integer()
  def count(dual_map) do
    map_size(dual_map.__data.map1)
  end

  @doc """
  Checks if `key` exists within DualMap.

  ## Examples

      iex> dm = DualMap.new([
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
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
    match?(%{^key_value => _}, dual_map.__data.map1)
      or
    match?(%{^key_value => _}, dual_map.__data.map2)
  end

  @doc """
  Checks if the pair `key_value` (a tuple size 2) exists in any of the internal maps either as key => value or as value => key.

  ## Examples

      iex> dm = DualMap.new([
        {"ns3", "192.168.0.4"},
        {"ns2", "192.168.0.3"},
        {"ns1", "192.168.0.2"}
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
  @spec member?(t(), key_value :: {any(), any()}) :: boolean()
  def member?(dual_map, {key, value}) do
    match?(%{^key => ^value}, dual_map.__data.map1)
      or
    match?(%{^key => ^value}, dual_map.__data.map2)
  end

end

defimpl Inspect, for: DualMap do
  import Inspect.Algebra
  def inspect(dual_map, opts) do
    to_doc(DualMap.to_list(dual_map), opts)
  end
end
