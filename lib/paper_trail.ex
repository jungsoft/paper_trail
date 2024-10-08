defmodule PaperTrail do
  import Ecto.Changeset

  alias Ecto.Changeset
  alias PaperTrail.Multi
  alias PaperTrail.RepoClient
  alias PaperTrail.Serializer
  alias PaperTrail.Version
  alias PaperTrail.VersionQueries

  @type repo :: module | nil
  @type strict_mode :: boolean | nil
  @type origin :: String.t() | nil
  @type meta :: map | nil
  @type originator :: Ecto.Schema.t() | nil
  @type prefix :: String.t() | nil
  @type multi_name :: Ecto.Multi.name() | nil
  @type queryable :: Ecto.Queryable.t()
  @type updates :: Keyword.t()

  @type options ::
          []
          | [
              repo: repo,
              strict_mode: strict_mode,
              origin: origin,
              meta: meta,
              originator: originator,
              prefix: prefix,
              model_key: multi_name,
              version_key: multi_name,
              return_operation: multi_name,
              returning: boolean()
            ]

  @type result :: {:ok, Ecto.Schema.t()} | {:error, Changeset.t()}
  @type all_result :: {integer, nil | [any]}

  @callback insert(Changeset.t(), options) :: result
  @callback insert!(Changeset.t(), options) :: Ecto.Schema.t()
  @callback insert_all(list(map()), options) :: all_result
  @callback update(Changeset.t(), options) :: result
  @callback update!(Changeset.t(), options) :: Ecto.Schema.t()
  @callback update_all(queryable, updates, options) :: all_result
  @callback delete(Changeset.t(), options) :: result
  @callback delete!(Changeset.t(), options) :: Ecto.Schema.t()
  @callback soft_delete(Ecto.Schema.t(), options) :: result
  @callback soft_delete!(Ecto.Schema.t(), options) :: Ecto.Schema.t()
  @callback soft_delete_all(queryable, options) :: all_result
  @callback get_version(Ecto.Schema.t()) :: Ecto.Query.t()
  @callback get_version(module, any) :: Ecto.Query.t()
  @callback get_version(module, any, keyword) :: Ecto.Query.t()

  @callback get_versions(Ecto.Schema.t()) :: Ecto.Query.t()
  @callback get_versions(module, any) :: Ecto.Query.t()
  @callback get_versions(module, any, keyword) :: Ecto.Query.t()

  @callback get_current_model(Version.t()) :: Ecto.Schema.t()

  defmacro __using__(options \\ []) do
    return_operation_options =
      case Keyword.fetch(options, :return_operation) do
        :error -> []
        {:ok, return_operation} -> [return_operation: return_operation]
      end

    client_options =
      [
        repo: RepoClient.repo(options),
        strict_mode: RepoClient.strict_mode(options)
      ] ++ return_operation_options

    quote do
      @behaviour PaperTrail

      @impl true
      def insert(changeset, options \\ []) when is_list(options) do
        PaperTrail.insert(changeset, merge_options(options))
      end

      @impl true
      def insert!(changeset, options \\ []) when is_list(options) do
        PaperTrail.insert!(changeset, merge_options(options))
      end

      @impl true
      def insert_all(entries, options \\ []) when is_list(options) do
        PaperTrail.insert_all(entries, merge_options(options))
      end

      @impl true
      def update(changeset, options \\ []) when is_list(options) do
        PaperTrail.update(changeset, merge_options(options))
      end

      @impl true
      def update!(changeset, options \\ []) when is_list(options) do
        PaperTrail.update!(changeset, merge_options(options))
      end

      @impl true
      def update_all(queryable, updates, options \\ []) when is_list(options) do
        PaperTrail.update_all(queryable, updates, merge_options(options))
      end

      @impl true
      def delete(struct, options \\ []) when is_list(options) do
        PaperTrail.delete(struct, merge_options(options))
      end

      @impl true
      def delete!(struct, options \\ []) when is_list(options) do
        PaperTrail.delete!(struct, merge_options(options))
      end

      @impl true
      def soft_delete(struct, options \\ []) when is_list(options) do
        PaperTrail.soft_delete(struct, merge_options(options))
      end

      @impl true
      def soft_delete!(struct, options \\ []) when is_list(options) do
        PaperTrail.soft_delete!(struct, merge_options(options))
      end

      @impl true
      def soft_delete_all(struct, options \\ []) when is_list(options) do
        PaperTrail.soft_delete_all(struct, merge_options(options))
      end

      @impl true
      def get_version(record) do
        VersionQueries.get_version(record, unquote(client_options))
      end

      @impl true
      def get_version(model_or_record, options) when is_list(options) do
        VersionQueries.get_version(model_or_record, merge_options(options))
      end

      @impl true
      def get_version(model_or_record, id) do
        VersionQueries.get_version(model_or_record, id, unquote(client_options))
      end

      @impl true
      def get_version(model, id, options) when is_list(options) do
        VersionQueries.get_version(model, id, merge_options(options))
      end

      @impl true
      def get_versions(record) do
        VersionQueries.get_versions(record, unquote(client_options))
      end

      @impl true
      def get_versions(model_or_record, options) when is_list(options) do
        VersionQueries.get_versions(model_or_record, merge_options(options))
      end

      @impl true
      def get_versions(model_or_record, id) do
        VersionQueries.get_versions(model_or_record, id, unquote(client_options))
      end

      @impl true
      def get_versions(model, id, options) when is_list(options) do
        VersionQueries.get_versions(model, id, merge_options(options))
      end

      @impl true
      def get_current_model(version) do
        VersionQueries.get_current_model(version, unquote(client_options))
      end

      @spec merge_options(keyword) :: keyword
      def merge_options(options), do: Keyword.merge(unquote(client_options), options)
    end
  end

  defdelegate get_version(record), to: VersionQueries
  defdelegate get_version(model_or_record, id_or_options), to: VersionQueries
  defdelegate get_version(model, id, options), to: VersionQueries
  defdelegate get_versions(record), to: VersionQueries
  defdelegate get_versions(model_or_record, id_or_options), to: VersionQueries
  defdelegate get_versions(model, id, options), to: VersionQueries
  defdelegate get_current_model(version, options \\ []), to: VersionQueries
  defdelegate make_version_struct(version, model, options), to: Serializer
  defdelegate get_sequence_from_model(changeset, options \\ []), to: Serializer
  defdelegate serialize(data, options), to: Serializer
  defdelegate get_sequence_id(table_name, options \\ []), to: Serializer
  defdelegate add_prefix(changeset, prefix), to: Serializer
  defdelegate get_item_type(data), to: Serializer
  defdelegate get_model_id(model), to: Serializer

  @doc """
  Inserts a record to the database with a related version insertion in one transaction
  """
  @spec insert(Changeset.t(), options) :: result
  def insert(changeset, options \\ []) do
    Multi.new()
    |> Multi.insert(changeset, options)
    |> Multi.commit(options)
  end

  @doc """
  Same as insert/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec insert!(Ecto.Schema.t(), options) :: Ecto.Schema.t()
  def insert!(changeset, options \\ []) do
    repo = RepoClient.repo(options)

    repo.transaction(fn ->
      case RepoClient.strict_mode(options) do
        true ->
          version_id = get_sequence_id("versions", options) + 1

          changeset_data =
            Map.get(changeset, :data, changeset)
            |> Map.merge(%{
              id: get_sequence_from_model(changeset, options) + 1,
              first_version_id: version_id,
              current_version_id: version_id
            })

          initial_version =
            make_version_struct(%{event: "insert"}, changeset_data, options)
            |> repo.insert!

          updated_changeset =
            changeset
            |> change(%{
              first_version_id: initial_version.id,
              current_version_id: initial_version.id
            })

          model = repo.insert!(updated_changeset)

          target_version =
            make_version_struct(%{event: "insert"}, model, options) |> serialize(options)

          Version.changeset(initial_version, target_version) |> repo.update!
          model

        _ ->
          model = repo.insert!(changeset)
          make_version_struct(%{event: "insert"}, model, options) |> repo.insert!
          model
      end
    end)
    |> elem(1)
  end

  @doc """
  Inserts all records from the database with a related version insertion in one transaction
  """
  @spec insert_all(list(map()), options) :: result
  def insert_all(entries, options \\ []) do
    Multi.new()
    |> Multi.insert_all(entries, options)
    |> Multi.commit(options)
  end

  @doc """
  Updates a record from the database with a related version insertion in one transaction
  """
  @spec update(Changeset.t(), options) :: result
  def update(changeset, options \\ []) do
    Multi.new()
    |> Multi.update(changeset, options)
    |> Multi.commit(options)
  end

  @doc """
  Same as update/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec update!(Ecto.Schema.t(), options) :: Ecto.Schema.t()
  def update!(changeset, options \\ []) do
    repo = RepoClient.repo(options)

    repo.transaction(fn ->
      case RepoClient.strict_mode(options) do
        true ->
          version_data =
            changeset.data
            |> Map.merge(%{
              current_version_id: get_sequence_id("versions", options)
            })

          target_changeset = changeset |> Map.merge(%{data: version_data})
          target_version = make_version_struct(%{event: "update"}, target_changeset, options)
          initial_version = repo.insert!(target_version)
          updated_changeset = changeset |> change(%{current_version_id: initial_version.id})
          model = repo.update!(updated_changeset)

          new_item_changes =
            initial_version.item_changes
            |> Map.merge(%{
              current_version_id: initial_version.id
            })

          initial_version |> change(%{item_changes: new_item_changes}) |> repo.update!
          model

        _ ->
          model = repo.update!(changeset)
          version_struct = make_version_struct(%{event: "update"}, changeset, options)
          repo.insert!(version_struct)
          model
      end
    end)
    |> elem(1)
  end

  @doc """
  Updates all records from the database with a related version insertion in one transaction
  """
  @spec update_all(queryable, updates, options) :: all_result
  def update_all(queryable, updates, options \\ []) do
    Multi.new()
    |> Multi.update_all(queryable, updates, options)
    |> Multi.commit(options)
    |> elem(1)
  end

  @doc """
  Deletes a record from the database with a related version insertion in one transaction
  """
  @spec delete(Changeset.t(), options) :: result
  def delete(struct, options \\ []) do
    Multi.new()
    |> Multi.delete(struct, options)
    |> Multi.commit(options)
  end

  @doc """
  Same as delete/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec delete!(Ecto.Schema.t(), options) :: Ecto.Schema.t()
  def delete!(struct, options \\ []) do
    repo = RepoClient.repo(options)

    repo.transaction(fn ->
      model = repo.delete!(struct, options)
      version_struct = make_version_struct(%{event: "delete"}, struct, options)
      repo.insert!(version_struct, options)
      model
    end)
    |> elem(1)
  end

  @doc """
  Soft deletion of a database record with a related version insert in a transaction
  """
  @spec soft_delete(Ecto.Schema.t(), options) :: result
  def soft_delete(struct, options \\ []) do
    Multi.new()
    |> Multi.soft_delete(struct, options)
    |> Multi.commit(options)
  end

  @doc """
  Same as soft_delete/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec soft_delete!(Ecto.Schema.t(), options) :: Ecto.Schema.t()
  def soft_delete!(struct, options \\ []) do
    repo = RepoClient.repo(options)

    repo.transaction(fn ->
      model = repo.soft_delete!(struct)
      version_struct = make_version_struct(%{event: "soft_delete"}, struct, options)
      repo.insert!(version_struct, options)
      model
    end)
    |> elem(1)
  end

  @doc """
  Soft delete all records from the database with a related version insertion in one transaction
  """
  @spec soft_delete_all(queryable, options) :: all_result
  def soft_delete_all(queryable, options \\ []) do
    Multi.new()
    |> Multi.soft_delete_all(queryable, options)
    |> Multi.commit(options)
    |> elem(1)
  end
end
