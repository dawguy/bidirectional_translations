defmodule BidirectionalTranslations.Repo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :language, :string, null: false
      add :english_text, :text, null: false
      add :target_text, :text, null: false
      add :source_url, :string

      timestamps(type: :utc_datetime)
    end

    create index(:articles, [:user_id])
  end
end
