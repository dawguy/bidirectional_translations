defmodule BidirectionalTranslations.Repo.Migrations.AddLibraryArticleIdToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :library_article_id, references(:library_articles, on_delete: :nilify_all)
    end

    create index(:articles, [:library_article_id])
  end
end
