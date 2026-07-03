defmodule BidirectionalTranslations.Library do
  @moduledoc """
  The Library context.

  Provides a shared pool of articles that any user can browse and adopt
  into their personal study list. Library articles are community-owned —
  they are not scoped to a single user, enabling future sharing features.
  """

  import Ecto.Query

  alias BidirectionalTranslations.Repo
  alias BidirectionalTranslations.Accounts.Scope
  alias BidirectionalTranslations.Library.Article, as: LibraryArticle
  alias BidirectionalTranslations.Translations
  alias BidirectionalTranslations.Translations.Article

  def total_session_count, do: Translations.total_session_count()

  @per_page 20

  @doc """
  Returns a page of library articles (newest first) with the submitter preloaded.
  """
  def list_library_articles(page \\ 1) do
    LibraryArticle
    |> order_by(desc: :inserted_at)
    |> preload(:submitted_by_user)
    |> limit(^@per_page)
    |> offset(^(@per_page * (page - 1)))
    |> Repo.all()
  end

  @doc """
  Returns a page of library articles with adoption status for the given user.
  Returns `{articles, adoptions, has_more}`.
  """
  def list_library_articles_with_adoption(%Scope{} = scope, page \\ 1) do
    library_articles = list_library_articles(page)
    adoptions = fetch_adoptions_for(scope, library_articles)
    has_more = count_library_articles() > page * @per_page
    {library_articles, adoptions, has_more}
  end

  @doc """
  Returns the total count of library articles.
  """
  def count_library_articles do
    Repo.aggregate(LibraryArticle, :count)
  end

  def get_library_article!(id) do
    LibraryArticle
    |> preload(:submitted_by_user)
    |> Repo.get!(id)
  end

  @doc """
  Creates a library article. Pass `submitted_by_user_id` optionally.
  """
  def create_library_article(attrs, submitted_by_user_id \\ nil) do
    attrs =
      if submitted_by_user_id,
        do: Map.put(attrs, "submitted_by_user_id", submitted_by_user_id),
        else: attrs

    %LibraryArticle{}
    |> LibraryArticle.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a library article.
  """
  def update_library_article(%LibraryArticle{} = article, attrs) do
    article
    |> LibraryArticle.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a changeset for a library article.
  """
  def change_library_article(%LibraryArticle{} = article, attrs \\ %{}) do
    LibraryArticle.changeset(article, attrs)
  end

  @doc """
  Adopts a library article for the given user: creates a personal Article
  with sessions scheduled according to the default schedule.
  """
  def adopt_library_article(%Scope{} = scope, %LibraryArticle{} = library_article) do
    attrs = %{
      "title" => library_article.title,
      "language" => library_article.language,
      "english_text" => library_article.english_text,
      "target_text" => library_article.target_text,
      "source_url" => library_article.source_url,
      "reader_url" => library_article.reader_url,
      "library_article_id" => library_article.id
    }

    Translations.create_article(scope, attrs)
  end

  @doc """
  Returns a map of `%{library_article_id => %{article_id: id, completed: n, total: n}}`
  for the given library articles that the current user has adopted.
  """
  def fetch_adoptions_for(%Scope{} = scope, library_articles) do
    ids = Enum.map(library_articles, & &1.id)

    if ids == [] do
      %{}
    else
      Article
      |> where(user_id: ^scope.user.id)
      |> where([a], a.library_article_id in ^ids)
      |> preload(:sessions)
      |> Repo.all()
      |> Map.new(fn article ->
        completed = Enum.count(article.sessions, &(&1.status == :completed))

        {article.library_article_id,
         %{
           article_id: article.id,
           completed: completed,
           total: total_session_count()
         }}
      end)
    end
  end

  @doc """
  Finds the personal Article for a user that was adopted from a given library article.
  Returns nil if not adopted.
  """
  def get_adoption(%Scope{} = scope, library_article_id) do
    Article
    |> where(user_id: ^scope.user.id, library_article_id: ^library_article_id)
    |> Repo.one()
  end

  @doc "Returns the CSS badge class for an adoption status map."
  def adoption_badge_class(%{completed: c, total: t}) when c >= t, do: "badge-success"
  def adoption_badge_class(_), do: "badge-warning"

  @doc "Returns the human-readable label for an adoption status map."
  def adoption_label(%{completed: c, total: t}) when c >= t, do: "Completed ✓"
  def adoption_label(%{completed: c, total: t}), do: "Studying #{c}/#{t}"
end
