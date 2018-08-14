defmodule Exmud.Engine.Schema.Component do
  use Exmud.Common.Schema

  schema "component" do
    field(:callback_module, :binary)
    belongs_to(:object, Exmud.Engine.Schema.Object, foreign_key: :object_id)
    has_many(:attributes, Exmud.Engine.Schema.Attribute, foreign_key: :component_id)
  end

  def new(params) do
    %Exmud.Engine.Schema.Component{}
    |> cast(params, [:callback_module, :object_id])
    |> validate_required([:callback_module, :object_id])
    |> foreign_key_constraint(:object_id)
    |> unique_constraint(:callback_module, name: :component_object_id_callback_module_index)
  end
end
