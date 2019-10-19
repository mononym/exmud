defmodule Exmud.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :nickname, :string
      add :slug, :string
      add :email, :string
      add :email_verified, :boolean, default: false, null: false
      add :tos_accepted, :boolean, default: false, null: false
      add :player_id, references(:players, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create unique_index(:profiles, [:nickname])
    create unique_index(:profiles, [:email])
    create index(:profiles, [:tos_accepted])
    create index(:profiles, [:player_id])
  end
end