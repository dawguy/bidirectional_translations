defmodule BidirectionalTranslations.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :article_id, references(:articles, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :direction, :string, null: false
      add :scheduled_date, :date, null: false
      add :status, :string, null: false, default: "pending"
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:sessions, [:article_id])
    create index(:sessions, [:user_id])
    create index(:sessions, [:user_id, :scheduled_date])
  end
end
