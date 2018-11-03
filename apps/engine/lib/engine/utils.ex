defmodule Exmud.Engine.Utils do
  @moduledoc false

  alias Exmud.Engine.Repo
  import Exmud.Common.Utils

  def cache, do: :exmud_engine_cache

  def engine_cfg( key ), do: cfg( :exmud_engine, key )

  @default_option_values %{
    max_retries: :unlimited,
    max_backoff: 100, # 100 milliseconds,
    min_backoff: 2 # 1 millisecond
  }
  def wrap_callback_in_retryable_transaction( callback, options \\ [] ) do
    options = Map.new( Keyword.merge( @default_option_values, options ) )

    execute_callback( callback, options, 0 )
  end

  defp execute_callback( callback, %{ max_retries: max_retries } = options, retries )
  when max_retries == :unlimited
  or max_retries >= retries do

    # If retries is > 0 this is not the first attempt to run this callback due to a serialization error, backoff
    if retries > 0 do
      # See: https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
      backoff = Enum.random( 0 .. min( options.max_backoff, 2 * trunc( :math.pow( 2, retries ) ) ) )
      # This process should be blocked during the backoff period as this should be synchronous from outside
      Process.sleep( backoff )
    end

    Repo.transaction(fn ->
      # This try/rescue construct exists so that tests can work (YUCK!)
      try do
        # Every transaction should have an isolated view of the data
        Repo.query("set transaction isolation level serializable;")
      rescue
        error in Postgrex.Error ->
          if error.postgres.code != :active_sql_transaction do
            raise error
          end
      end

      try do
        callback.()
      rescue
        error in Postgrex.Error ->
          if error.postgres.code == :serialization_failure do
            Repo.rollback( :serialization_failure )
          else
            raise error
          end
      end
    end)
    |> case do
      { :error, :serialization_failure } ->
        execute_callback( callback, options, retries + 1 )
      { _, result } ->
        result
    end
  end

  defp execute_callback( _, _, _ ) do
    { :error, :retries_exceeded }
  end
end