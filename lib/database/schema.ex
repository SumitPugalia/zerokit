defmodule Zerokit.Schema do
  @moduledoc false
  import Ecto.Query

  defmacro __using__(_opts) do
    schema =
      __CALLER__.module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    fetch_function_name = String.to_atom("fetch_#{schema}")
    list_function_name = String.to_atom("list_#{schema}")
    create_function_name = String.to_atom("create_#{schema}")
    upsert_function_name = String.to_atom("upsert_#{schema}")
    update_function_name = String.to_atom("update_#{schema}")

    quote do
      use Ecto.Schema
      import Ecto.{Query, Changeset}, warn: false

      def changeset(model, params) do
        model |> cast(params, [])
      end

      def unquote(fetch_function_name)(id_or_query, opts \\ [])

      def unquote(fetch_function_name)(id, opts) when is_binary(id) or is_integer(id) do
        __MODULE__
        |> where(id: ^id)
        |> Zerokit.Schema.handle_get(unquote(schema), opts)
      end

      def unquote(fetch_function_name)(queries, opts) when is_map(queries) or is_list(queries) do
        queries = Enum.to_list(queries)

        __MODULE__
        |> where(^queries)
        |> Zerokit.Schema.handle_get(unquote(schema), opts)
      end

      def unquote(fetch_function_name)(_queries, _opts) do
        Zerokit.Schema.not_found_error(unquote(schema))
      end

      def unquote(list_function_name)(id_or_query, opts \\ [])

      def unquote(list_function_name)(id, opts) when is_binary(id) or is_integer(id) do
        __MODULE__
        |> where(id: ^id)
        |> Zerokit.Schema.handle_all(unquote(schema), opts)
      end

      def unquote(list_function_name)(queries, opts) when is_map(queries) or is_list(queries) do
        queries = Enum.to_list(queries)

        __MODULE__
        |> where(^queries)
        |> Zerokit.Schema.handle_all(unquote(schema), opts)
      end

      def unquote(list_function_name)(_queries, _opts) do
        Zerokit.Schema.not_found_error(unquote(schema))
      end

      def unquote(upsert_function_name)(module \\ nil, params, opts \\ [])

      def unquote(upsert_function_name)(nil, %{} = params, opts) do
        __MODULE__
        |> struct()
        |> unquote(upsert_function_name)(params)
      end

      def unquote(upsert_function_name)(%{__struct__: __MODULE__, id: id} = entity, %{} = params, opts)
          when not is_nil(id) do
        {changeset_function, params} = Map.pop(params, :with_changeset, &__MODULE__.changeset/2)

        entity
        |> changeset_function.(params)
        |> __MODULE__.repo().insert_or_update()
      end

      def unquote(upsert_function_name)(
            %{__struct__: __MODULE__} = entity,
            %{} = %{ignore_id: true} = params,
            opts
          ) do
        {changeset_function, params} = Map.pop(params, :with_changeset, &__MODULE__.changeset/2)

        entity
        |> changeset_function.(params)
        |> __MODULE__.repo().insert_or_update()
      end

      def unquote(upsert_function_name)(%{__struct__: __MODULE__, id: nil} = entity, %{} = params, _opts) do
        {query, params} = Map.pop(params, :with_query)
        entity_params = Map.from_struct(entity)

        id = params[:id] || params["id"]

        result =
          cond do
            is_nil(query) and id -> apply(__MODULE__, :"fetch_#{unquote(schema)}", [id])
            is_function(query, 0) -> query.()
            true -> Zerokit.Schema.not_found_error(unquote(schema))
          end

        entity =
          case result do
            {:ok, entity} -> entity
            {:error, _} -> struct(__MODULE__, Map.merge(entity_params, %{id: id}))
          end

        unquote(upsert_function_name)(entity, Map.put(params, :ignore_id, true))
      end

      def unquote(update_function_name)(%{__struct__: __MODULE__} = entity, %{} = params, opts) do
        {changeset_function, params} = Map.pop(params, :with_changeset, &__MODULE__.changeset/2)

        entity
        |> changeset_function.(params)
        |> __MODULE__.repo().update()
      end

      def unquote(create_function_name)(module \\ nil, params)

      def unquote(create_function_name)(nil, %{} = params) do
        __MODULE__
        |> struct()
        |> unquote(create_function_name)(params)
      end

      def unquote(create_function_name)(%{__struct__: __MODULE__} = entity, %{} = params) do
        {changeset_function, params} = Map.pop(params, :with_changeset, &__MODULE__.changeset/2)

        entity
        |> changeset_function.(params)
        |> __MODULE__.repo().insert()
      end

      defoverridable [
        {unquote(fetch_function_name), 1},
        {unquote(fetch_function_name), 2},
        {unquote(list_function_name), 1},
        {unquote(list_function_name), 2},
        {unquote(create_function_name), 2},
        {unquote(upsert_function_name), 2},
        {unquote(update_function_name), 2},
        {:changeset, 2}
      ]
    end
  end

  def put_order_by(%Ecto.Query{} = query, order_by) when is_list(order_by) do
    {_, module} = query.from.source
    fields = Enum.map(module.__schema__(:fields), &to_string/1)
    new_order_by = atomize_order_by(order_by, fields)

    query |> order_by(^new_order_by)
  end

  def put_order_by(%Ecto.Query{} = query, _) do
    query
  end

  def handle_get(queryable, schema, opts) do
    queryable
    |> do_preload(opts[:preload])
    |> __MODULE__.repo().one()
    |> case do
      nil ->
        not_found_error(schema)

      entity ->
        {:ok, entity}
    end
  end

  def handle_all(queryable, _schema, opts) do
    entity =
      queryable
      |> do_preload(opts[:preload])
      |> __MODULE__.repo().all()

    {:ok, entity}
  end

  def not_found_error(schema) do
    {:error, String.to_atom("#{schema}_not_found")}
  end

  # PRIVATE
  defp do_preload(queryable, nil) do
    queryable
  end

  defp do_preload(queryable, preload) do
    queryable |> preload(^preload)
  end

  defp atomize_order_by(order_by, accepted_fields) when is_list(order_by) do
    order_by
    |> Enum.map(&do_atomize_order_by(&1, accepted_fields))
    |> Enum.reject(&is_nil/1)
  end

  defp do_atomize_order_by({k, v}, accepted_fields) when k in ["asc", "desc"] do
    do_atomize_order_by({String.to_existing_atom(k), v}, accepted_fields)
  end

  defp do_atomize_order_by({k, v}, accepted_fields) when k in [:asc, :desc] do
    string_v = to_string(v)

    if string_v in accepted_fields do
      {k, String.to_existing_atom(string_v)}
    end
  end

  defp do_atomize_order_by(_, _), do: nil
end
