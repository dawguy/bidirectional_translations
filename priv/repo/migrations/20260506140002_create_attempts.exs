defmodule BidirectionalTranslations.Repo.Migrations.CreateAttempts do
  use Ecto.Migration

  def change do
    create table(:attempts) do
      add :session_id, references(:sessions, on_delete: :delete_all), null: false
      add :body, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:attempts, [:session_id])
  end
end
