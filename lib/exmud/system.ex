defmodule Exmud.System do
  @moduledoc """
  A behaviour module for implementing a system within the Exmud engine.
  
  Systems form the backbone of the engine. They drive time and event based
  actions, covering everything from weather effects to triggering AI actions.
  
  Systems do not have to run on a set schedule and instead can only react to
  events, and vice versa. See documentation for `c:initialize/1` for details.
  
  ## Callbacks
  There are 5 callbacks required to be implemented in a system. By adding
  `use Exmud.System` to your module, Elixir will automatically define all
  5 callbacks for you, leaving it up to you to implement the ones
  you want to customize.
  """


  #
  # Behavior definition and default callback setup
  #


  @doc """
  Invoked when a message has been sent to the system.
  
  Must return a tuple in the form of `{reply, state}`. If the message was sent
  as a cast the value of `reply` is ignored.
  """
  @callback handle_message(message, state) :: {reply, state}
  
  @doc """
  Invoked the first time a system is started. This callback will be invoked
  before `start/2`.
  
  Must return a new state. This will be the state used by all other callbacks.
  """
  @callback initialize(args) :: state
  
  @doc """
  Invoked when the main loop of the system is to be run again.
  
  Must return a new state.
  """
  @callback run(args) :: state
  
  @doc """
  Invoked when the system is being started.
  
  Must return a new state.
  """
  @callback start(args, state) :: state
  
  @doc """
  Invoked when the system is being stopped.
  
  Must return a new state.
  """
  @callback stop(args, state) :: state

  @typedoc "Arguments passed through to a callback module."
  @type args :: term
  
  @typedoc "A message passed through to a callback module."
  @type message :: term
  
  @typedoc "A reply passed through to the caller."
  @type reply :: term
  
  @typedoc "State used by the callback module."
  @type state :: term
  
  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Exmud.System
      
      @doc false
      def handle_message(message, state), do: {message, state}
      
      @doc false
      def initialize(args), do: Map.new()
      
      @doc false
      def run(state), do: state
      
      @doc false
      def start(_args, state), do: state
      
      @doc false
      def stop(_args, state), do: state

      defoverridable [handle_message: 2,
                      initialize: 1,
                      run: 1,
                      start: 2,
                      stop: 2]
    end
  end


  #
  # API
  #
  

  alias Exmud.Registry
  alias Exmud.Repo
  alias Exmud.Schema.System, as: S
  import Ecto.Query
  
  @system_category "system"


  def call(key, message) do
    case Registry.read_key(key, @system_category) do
      {:error, :no_such_key} -> {:error, :no_such_system}
      {:ok, pid} ->
        GenServer.call(pid, {:message, message})
    end
  end

  def cast(system, message) do
    case Registry.read_key(system, @system_category) do
      {:error, :no_such_key} -> {:error, :no_such_system}
      {:ok, pid} ->
        GenServer.cast(pid, {:message, message})
        :ok
    end
  end

  def purge(key) do
    Repo.one(
      from system in S,
      where: system.key == ^key,
      select: system
    )
    |> case do
      nil -> {:error, :no_such_system}
      system ->
        {:ok, _} = Repo.delete(system)
        {:ok, :erlang.binary_to_term(system.state)}
    end
  end

  def running?(key) do
    {result, _reply} = Registry.read_key(key, @system_category)
    result == :ok
  end

  def start(key, callback_module, args \\ %{}) do
    if running?(key) do
      {:error, :already_started}
    else
      {:ok, _} = Supervisor.start_child(Exmud.SystemSup, [key, callback_module, args])
      :ok
    end
  end

  def stop(key, args \\ %{}) do
    case Registry.read_key(key, @system_category) do
      {:ok, pid} ->  GenServer.call(pid, {:stop, args})
      {:error, :no_such_key} -> {:error, :no_such_system}
    end
  end
  
  
  #
  # Internal Functions
  #
  
  
  def send_message(method, key, message) do
    case Registry.read_key(key, @system_category) do
      {:error, :no_such_key} -> {:error, :no_such_system}
      {:ok, pid} ->
        apply(GenServer, method, [pid, {:message, message}])
    end
  end
end