defmodule BidirectionalTranslations.Repo.Migrations.AddReaderUrlToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :reader_url, :string
    end
  end
end
