defmodule ExmudWeb.CallbackController do
  use ExmudWeb, :controller

  alias Exmud.Builder
  alias Exmud.Builder.Callback

  def index(conn, _params) do
    callbacks =
      Builder.list_callbacks()
      |> Enum.map(fn callback ->
        %{callback | docs: Exmud.Util.get_module_docs(callback.module)}
      end)

    render(conn, "index.html", callbacks: callbacks)
  end

  def new(conn, _params) do
    changeset = Builder.change_callback(%Callback{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"callback" => callback_params}) do
    case Builder.create_callback(callback_params) do
      {:ok, callback} ->
        conn
        |> put_flash(:info, "Callback created successfully.")
        |> redirect(to: Routes.callback_path(conn, :show, callback))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    callback = Builder.get_callback!(id)

    render(conn, "show.html",
      callback: callback,
      docs: Exmud.Util.get_module_docs(callback.module)
    )
  end

  def edit(conn, %{"id" => id}) do
    callback = Builder.get_callback!(id)
    changeset = Builder.change_callback(callback)

    render(conn, "edit.html",
      callback: callback,
      changeset: changeset,
      docs: Exmud.Util.get_module_docs(callback.module),
      config: Poison.encode!(callback.config),
      config_schema: Poison.encode!(callback.module.config_schema()),
      has_config_error?: false
    )
  end

  def update(conn, %{"id" => id, "callback" => callback_params}) do
    callback = Builder.get_callback!(id)

    with {:ok, config} <- extract_config(callback_params),
         :ok <-
           callback.module.config_schema()
           |> ExJsonSchema.Schema.resolve()
           |> ExJsonSchema.Validator.validate(config),
         callback_params <- Map.put(callback_params, "config", config),
         {:ok, callback} <- Builder.update_callback(callback, callback_params) do
      conn
      |> put_flash(:info, "Callback updated successfully.")
      |> redirect(to: Routes.callback_path(conn, :show, callback))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html",
          callback: callback,
          changeset: changeset,
          docs: Exmud.Util.get_module_docs(callback.module),
          config: Poison.encode!(callback.config),
          config_schema: Poison.encode!(callback.module.config_schema()),
          has_config_error?: true
        )

      {:error, :invalid_json} ->
        conn
        |> put_flash(:error, "Invalid JSON submitted.")
        |> render("edit.html",
          callback: callback,
          changeset: Builder.change_callback(callback),
          docs: Exmud.Util.get_module_docs(callback.module),
          config: Poison.encode!(callback.config),
          config_schema: Poison.encode!(callback.module.config_schema()),
          has_config_error?: true
        )

      {:error, errors} ->
        {:ok, config} = extract_config(callback_params)
        errors = Exmud.Util.exjson_validator_errors_to_changeset_errors(:config, errors)
        changeset = Builder.change_callback(callback)

        changeset = %{
          changeset
          | errors: Keyword.merge(changeset.errors, errors),
            valid?: false,
            action: :insert
        }

        render(conn, "edit.html",
          callback: callback,
          changeset: changeset,
          docs: Exmud.Util.get_module_docs(callback.module),
          config: Poison.encode!(config),
          config_schema: Poison.encode!(callback.module.config_schema()),
          has_config_error?: true
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    callback = Builder.get_callback!(id)
    {:ok, _callback} = Builder.delete_callback(callback)

    conn
    |> put_flash(:info, "Callback deleted successfully.")
    |> redirect(to: Routes.callback_path(conn, :index))
  end

  defp extract_config(params) do
    case Poison.decode(params["updated_config"]) do
      {:ok, updated_config} ->
        {:ok, updated_config}

      {:error, _} ->
        {:error, :invalid_json}
    end
  end
end