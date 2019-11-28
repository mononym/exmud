defmodule Exmud.Repo.Migrations.CreateEngines do
  use Ecto.Migration

  def change do
    create table(:muds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :slug, :string
      add :player_id, references(:players, on_delete: :nilify_all, type: :binary_id)

      timestamps()
    end

    create unique_index(:muds, [:name])
    create unique_index(:muds, [:slug])
  end
end
