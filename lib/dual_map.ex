defmodule DualMap do
  @moduledoc """
  Documentation for `DualMap`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> DualMap.hello()
      :world

  """
  @typedoc "DualMap"
  @type t :: %{
    master_key1 :: any() => map(),
    master_key2 :: any() => map(),
    __master_keys_map: %{
      master_key1 :: any() => master_key2 :: any(),
      master_key2 :: any() => master_key1 :: any(),
    },
    __ordered_master_keys: list(any())
  }


  @spec new({master_key1 :: any(), master_key2 :: any()}) :: t()
  def new({master_key1, master_key2}), do: new(master_key1, master_key2)

  @spec new(master_key1 :: any(), master_key2 :: any()) :: t()
  def new(master_key1, master_key2) do
    %{
      master_key1 => %{},
      master_key2 => %{},
      __master_keys_map: %{
        master_key1 => master_key2,
        master_key2 => master_key1
      },
      __ordered_master_keys: [master_key1, master_key2]
    }
  end

  @spec delete(t(), master_key1 :: any(), key1 :: any()) :: t()
  def delete(dual_map, master_key1, key1) do
    case dual_map[master_key1][key1] do
      key2 when not is_nil(key2) ->
        master_key2 = dual_map.__master_keys_map[master_key1]
        map_key1 = Map.delete(dual_map[master_key1], key1)
        map_key2 = Map.delete(dual_map[master_key2], key2)
        %{dual_map |
          master_key1 => map_key1,
          master_key2 => map_key2
        }

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
    map_key1 = Map.put(dual_map[master_key1], key, value)
    map_key2 = Map.put(dual_map[master_key2], value, key)
    %{dual_map |
      master_key1 => map_key1,
      master_key2 => map_key2
    }
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
    Map.get(dual_map[master_key], key, default)
  end

  @spec get_map(t(), any()) :: map()
  def get_map(dual_map, master_key) do
    Map.fetch!(dual_map, master_key)
  end

  @spec keys(t(), any()) :: list()
  def keys(dual_map, master_key) do
    Map.keys(dual_map[master_key])
  end

  @spec values(t(), any()) :: list()
  def values(dual_map, master_key) do
    Map.values(dual_map[master_key])
  end

  @spec to_list(t()) :: [{any(), any()}]
  def to_list(dual_map, option \\ nil)
  def to_list(dual_map, nil) do
    [master_key, _] = dual_map.__ordered_master_keys
    Map.to_list(dual_map[master_key])
  end
  def to_list(dual_map, :pair_inverted) do
    [_, master_key] = dual_map.__ordered_master_keys
    Map.to_list(dual_map[master_key])
  end

  @spec fetch(t(), any(), any()) :: {:ok, any()} | :error
  def fetch(dual_map, master_key, key) do
    Map.fetch(dual_map[master_key], key)
  end

  @spec fetch!(t(), any(), any()) :: any()
  def fetch!(dual_map, master_key, key) do
    Map.fetch!(dual_map[master_key], key)
  end

  @spec equal?(t(), t()) :: boolean()
  def equal?(dual_map1, dual_map2), do: Map.equal?(dual_map1, dual_map2)

  @spec count(t()) :: pos_integer()
  def count(dual_map) do
    [master_key, _] = dual_map.__ordered_master_keys
    map_size(dual_map[master_key])
  end

  @spec has?(t(), any()) :: boolean()
  def has?(dual_map, key_value) do
    [master_key1, master_key2] = dual_map.__ordered_master_keys
    match?(%{^key_value => _}, dual_map[master_key1])
      or
    match?(%{^key_value => _}, dual_map[master_key2])
  end

  @spec member?(t(), {any(), any()}) :: boolean()
  def member?(dual_map, {key, value}) do
    [master_key1, master_key2] = dual_map.__ordered_master_keys
    match?(%{^key => ^value}, dual_map[master_key1])
      or
    match?(%{^key => ^value}, dual_map[master_key2])
  end

end
