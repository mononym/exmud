defmodule Exmud.Engine.SystemRunner do
  @moduledoc false

  alias Ecto.Changeset
  alias Exmud.Engine.Cache
  alias Exmud.Engine.Repo
  alias Exmud.Engine.Schema.System
  import Ecto.Query
  import Exmud.Common.Utils
  import Exmud.Engine.Utils
  require Logger
  use GenServer

  @system_category "system"


  #
  # Worker Callback
  #


  @doc false
  def start_link(key, callback_module, args) do
    GenServer.start_link(__MODULE__, {key, callback_module, args})
  end


  #
  # GenServer Callbacks
  #


  @doc false
  @lint {Credo.Check.Refactor.PipeChainStart, false}
  def init({key, callback_module, args}) do
    if Cache.put(key, @system_category, self()) == :ok do
      Repo.one(
        from system in System,
          where: system.key == ^key,
          select: system
      )
      |> case do
        nil ->
          initial_state = callback_module.initialize(args)
          serialized_state = serialize(initial_state)
          System.new(%System{}, %{key: key, state: serialized_state})
          |> Repo.insert()
          |> case do
            {:ok, system} ->
              {state, timeout} = callback_module.start(args, initial_state) |> normalize_result()
              maybe_queue_run(timeout)
              {:ok, %{callback_module: callback_module, state: state, system: system}}
            {:error, changeset} ->
              {:stop, {:shutdown, {:error, changeset.errors}}}
          end
        system ->
          initial_state = deserialize(system.state)

          {state, timeout} = callback_module.start(args, initial_state) |> normalize_result()
          maybe_queue_run(timeout)

          Logger.info("System started with key `#{key}` and callback module `#{callback_module}`")
          {:ok, %{callback_module: callback_module, state: state, system: system}}
      end
    else
      {:stop, {:shutdown, :already_started}}
    end
  end

  @doc false
  def handle_call(:state, _from, %{state: state} = data) do
    {:reply, state, data}
  end

  @doc false
  def handle_call({:stop, args}, _from, %{callback_module: callback_module, system: system, state: state} = _data) do
    new_state = callback_module.stop(args, state)
    :ok = Cache.delete(system.key, @system_category)
    serialized_state = serialize(new_state)

    System.update(system, %{state: serialize(new_state)})
    |> Repo.update()
    |> case do
      {:ok, system} ->
        {:stop, :normal, :ok, system}
      {:error, changeset} ->
        {:stop, :normal, {:error, changeset.errors}, system}
    end
  end

  @doc false
  def handle_call({:message, message}, _from,  %{callback_module: callback_module, state: state} = data) do
    case callback_module.handle_message(message, state) do
      {response, new_state, timeout} ->
        maybe_queue_run(timeout)
        {:reply, response, Map.put(data, :state, new_state)}
      {response, new_state} ->
        {:reply, response, Map.put(data, :state, new_state)}
    end
  end

  @doc false
  def handle_cast({:message, message}, %{callback_module: callback_module, state: state} = data) do
    {_response, new_state} = callback_module.handle_message(message, state)

    {:noreply, Map.put(data, :state, new_state)}
  end

  @doc false
  def handle_info(:run, %{callback_module: callback_module, state: state} = data) do
    {new_state, timeout} = callback_module.run(state) |> normalize_result()
    maybe_queue_run(timeout)

    {:noreply, Map.put(data, :state, new_state)}
  end


  #
  # Private Functions
  #


  defp normalize_result(result) when is_tuple(result), do: result
  defp normalize_result(state), do: {state, engine_cfg(:default_system_run_timeout)}

  defp maybe_queue_run(timeout) do
    if timeout !== :never do
      Process.send_after(self(), :run, timeout)
    end
  end
end