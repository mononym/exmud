defmodule Model.Link do
  import Ecto.Changeset

  use Ecto.Schema

  schema "link" do
    field(:type, :string)
    field(:state, :map, default: %{})
    belongs_to(:to, Model.Object, foreign_key: :to_id)
    belongs_to(:from, Model.Object, foreign_key: :from_id)

    timestamps()
  end

  def new(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, [:state, :from_id, :type, :to_id])
    |> validate_required([:state, :from_id, :type, :to_id])
    |> foreign_key_constraint(:to_id)
    |> foreign_key_constraint(:from_id)
  end

  def update(link, params) when is_map(params) do
    link
    |> cast(params, [:type, :state])
    |> Model.Validations.validate_map(:state)
  end
end
