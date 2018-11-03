defmodule Exmud.Engine.Command.ExecutionContext do
  @moduledoc """
  An ExecutionContext struct contains everything required for the processing of a Command.

  Much like Plug, this context is intended to be passed between multiple middlewares, some of which may need to run before others to populate required data.
  """

  @enforce_keys [ :caller, :raw_input ]
  defstruct [
    :args, # Parsed arguments for the command.
    :caller, # Object that is doing the calling. All Commands are executed by Objects, even if triggered by a Player.
    { :data, %{} }, # Arbitrary data that can be set and used from any of the middlewares.
    :command_list, # List of Commands generated by merging all accessible Command Sets.
    :matched_command, # The Command which was actually matched.
    :matched_key, # Key that actually matched. For 'move west' the matched_key would be 'move'.
    { :events, [] }, # Events to be executed as part of the pipeline. Events can be added by any of the middlewares including the Command being executed. All transaction based events are executed within the transaction while events such as sending messages will execute after--and only if--the transaction commits successfully.
    :owner, # The Object the matched command belongs to. Does not have to be the caller, and often won't be.
    :raw_input, # The raw text input before any processing.
    :raw_args # The raw argument string, which is the raw_input minus the matched command.
  ]
  @type t :: %Exmud.Engine.Command.ExecutionContext{
    args: term,
    command_list: [ Exmud.Engine.Command.t() ],
    matched_command: Exmud.Engine.Command.t(),
    matched_key: String.t(),
    events: [ Exmud.Engine.Event.t() ],
    owner: integer,
    raw_input: String.t(),
    raw_args: String.t(),
    caller: integer,
    data: Map.t()
  }

  def get( context, key ) do
     Map.get( context.data, key )
  end

  def has_key?( context, key ) do
     Map.has_key?( context.data, key )
  end

  def put( context, key, value ) do
    %{ context | data: Map.put( context.data, key, value ) }
  end
end

defimpl String.Chars, for: Exmud.Engine.Command.ExecutionContext do
  def to_string( execution ) do
    "%{caller: '#{ execution.caller }', matched_key:'#{ execution.matched_key }'," <>
    " owner: '#{ execution.owner }', raw_input: '#{ execution.raw_input }'}"
  end
end