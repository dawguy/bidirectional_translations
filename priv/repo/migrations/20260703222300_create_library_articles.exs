defmodule BidirectionalTranslations.Repo.Migrations.CreateLibraryArticles do
  use Ecto.Migration

  def change do
    create table(:library_articles) do
      add :title, :string, null: false
      add :language, :string, null: false
      add :english_text, :text, null: false
      add :target_text, :text, null: false
      add :source_url, :string
      add :reader_url, :string
      add :submitted_by_user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:library_articles, [:language])
    create index(:library_articles, [:submitted_by_user_id])
  end
end
