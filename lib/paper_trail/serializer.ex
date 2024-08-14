defmodule PaperTrail.Serializer do
  import Ecto.Query

  alias PaperTrail.RepoClient
  alias PaperTrail.Version

  @type options :: PaperTrail.options()
  @type model :: nil | Ecto.Changeset.t() | struct() | [Ecto.Changeset.t() | struct()]

  @default_ignored_ecto_types [Ecto.UUID, :binary_id, :binary]

  def make_version_struct(%{event: event}, model_or_changeset, options) do
    originator = RepoClient.originator()
    originator_ref = options[originator[:name]] || options[:originator]

    %Version{
      event: event,
      item_type: get_item_type(model_or_changeset),
      item_id: get_model_id(model_or_changeset),
      item_changes: serialize(model_or_changeset, options, event),
      originator_id:
        case originator_ref do
          nil -> nil
          _ -> originator_ref |> Map.get(:id)
        end,
      origin: options[:origin],
      meta: options[:meta]
    }
    |> add_prefix(options[:prefix])
  end

  @spec make_version_query(map, PaperTrail.queryable(), Keyword.t() | map, PaperTrail.options()) ::
          Ecto.Query.t()
  def make_version_query(%{event: event}, queryable, changes, options) do
    {_table, schema} = queryable.from.source
    item_type = schema |> struct() |> get_item_type()
    [primary_key] = schema.__schema__(:primary_key)
    changes_map = Map.new(changes)
    originator = RepoClient.originator()
    originator_ref = options[originator[:name]] || options[:originator]
    originator_id = if(originator_ref, do: originator_ref.id, else: nil)
    originator_id_type = RepoClient.originator_type()
    origin = options[:origin]
    meta = options[:meta]

    queryable
    |> exclude(:select)
    |> select([q], %{
      event: type(^event, :string),
      item_type: type(^item_type, :string),
      item_id: field(q, ^primary_key),
      item_changes: type(^changes_map, :map),
      originator_id: type(^originator_id, ^originator_id_type),
      origin: type(^origin, :string),
      meta: type(^meta, :map),
      inserted_at: type(fragment("CURRENT_TIMESTAMP"), :naive_datetime)
    })
  end

  def get_sequence_from_model(changeset, options \\ []) do
    table_name =
      case Map.get(changeset, :data) do
        nil -> changeset.__struct__.__schema__(:source)
        _ -> changeset.data.__struct__.__schema__(:source)
      end

    get_sequence_id(table_name, options)
  end

  def get_sequence_id(table_name, options) do
    Ecto.Adapters.SQL.query!(
      RepoClient.repo(options),
      "select last_value FROM #{table_name}_id_seq"
    ).rows
    |> List.first()
    |> List.first()
  end

  @spec serialize(model(), options()) :: nil | map() | [map()]
  @spec serialize(model(), options(), String.t()) :: nil | map() | [map()]
  def serialize(model, options, event \\ "insert")

  def serialize(nil, _options, _event), do: nil

  def serialize(list, options, event) when is_list(list) do
    Enum.map(list, &serialize(&1, options, event))
  end

  def serialize(
        %Ecto.Changeset{data: %schema{}, changes: changes},
        options,
        "update"
      ) do
    changes
    |> schema.__struct__()
    |> do_serialize(options, Map.keys(changes))
  end

  def serialize(%Ecto.Changeset{data: data}, options, _event), do: do_serialize(data, options)

  def serialize(%_schema{} = model, options, _event), do: do_serialize(model, options)

  @spec do_serialize(struct, options, [atom] | nil) :: map
  defp do_serialize(%schema{} = model, options, changed_fields \\ nil) do
    fields = changed_fields || schema.__schema__(:fields)
    adapter = get_adapter(options)
    changes = model |> Map.from_struct() |> Map.take(fields)
    associations = serialize_associations(model, options)

    changes
    |> Map.take(schema.__schema__(:fields))
    |> Enum.map(&dump_field!(&1, schema, adapter, options))
    |> Map.new()
    |> Map.merge(associations)
  end

  defp get_adapter(options) do
    repo = RepoClient.repo(options)

    case Ecto.Repo.Registry.lookup(repo.get_dynamic_repo()) do
      %{adapter: adapter} -> adapter
      {adapter, _adapter_meta} -> adapter
    end
  end

  @spec serialize_associations(struct, options) :: map
  defp serialize_associations(%schema{} = model, options) do
    association_fields = schema.__schema__(:associations)

    model
    |> Map.take(association_fields)
    |> Enum.filter(fn {_field, value} -> not is_nil(value) and Ecto.assoc_loaded?(value) end)
    |> Enum.map(fn {field, value} -> {field, serialize_association(value, options)} end)
    |> Enum.reject(&(match?({_, nil}, &1) || match?({_, []}, &1)))
    |> Map.new()
  end

  defp serialize_association(list, options) when is_list(list) do
    list
    |> Enum.map(&serialize_association(&1, options))
    |> Enum.reject(&is_nil/1)
  end

  defp serialize_association(
         %Ecto.Changeset{data: %schema{} = data, changes: changes, action: event},
         options
       ) do
    case event do
      :replace ->
        data = do_serialize(data, options)
        %{event: event, data: data}

      :update when changes == %{} ->
        nil

      _ ->
        changes =
          changes
          |> schema.__struct__()
          |> do_serialize(options, Map.keys(changes))

        if changes == %{} do
          nil
        else
          %{event: event, changes: changes}
        end
    end
  end

  defp serialize_association(%_schema{} = model, options),
    do: %{"event" => "insert", "changes" => do_serialize(model, options)}

  defp dump_field!({field, %Ecto.Changeset{action: event} = value}, _schema, _adapter, options) do
    {field, serialize(value, options, event)}
  end

  defp dump_field!(
         {field, [%Ecto.Changeset{action: event} | _] = changesets},
         _schema,
         _adapter,
         options
       ) do
    serialized_changesets =
      Enum.map(changesets, fn changeset -> serialize(changeset, options, event) end)

    {field, serialized_changesets}
  end

  defp dump_field!({field, value}, schema, adapter, _options) do
    dumper = schema.__schema__(:dump)
    {alias, type} = Map.fetch!(dumper, field)

    dumped_value =
      if type in ignored_ecto_types(),
        do: serialize_binary(value),
        else: do_dump_field!(schema, field, type, value, adapter)

    {alias, dumped_value}
  end

  defp do_dump_field!(schema, field, type, value, adapter) do
    case Ecto.Type.adapter_dump(adapter, type, value) do
      {:ok, value} ->
        value

      :error ->
        raise Ecto.ChangeError,
              "value `#{inspect(value)}` for `#{inspect(schema)}.#{field}` " <>
                "does not match type #{inspect(type)}"
    end
  end

  def add_prefix(changeset, nil), do: changeset
  def add_prefix(changeset, prefix), do: Ecto.put_meta(changeset, prefix: prefix)

  def get_item_type(%Ecto.Changeset{data: data}), do: get_item_type(data)
  def get_item_type(%schema{}), do: schema |> Module.split() |> List.last()

  def get_model_id(%Ecto.Changeset{data: data}), do: get_model_id(data)

  def get_model_id(model) do
    {_, model_id} = List.first(Ecto.primary_key(model))

    case PaperTrail.Version.__schema__(:type, :item_id) do
      :integer ->
        model_id

      _ ->
        "#{model_id}"
    end
  end

  @spec ignored_ecto_types :: [atom]
  defp ignored_ecto_types do
    :not_dumped_ecto_types
    |> get_env([])
    |> Kernel.++(@default_ignored_ecto_types)
    |> Enum.uniq()
  end

  @spec get_env(atom, any) :: any
  defp get_env(key, default), do: Application.get_env(:paper_trail, key, default)

  @spec serialize_binary(binary()) :: String.t() | [integer()]
  defp serialize_binary(binary) when is_binary(binary) do
    if String.valid?(binary) do
      binary
    else
      :binary.bin_to_list(binary)
    end
  end

  defp serialize_binary(value), do: value
end
