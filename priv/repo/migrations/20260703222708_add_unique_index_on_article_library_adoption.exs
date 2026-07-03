defmodule BidirectionalTranslations.Repo.Migrations.AddUniqueIndexOnArticleLibraryAdoption do
  use Ecto.Migration

  def change do
    create unique_index(:articles, [:user_id, :library_article_id],
             where: "library_article_id IS NOT NULL",
             name: :articles_user_library_unique
           )
  end
end
