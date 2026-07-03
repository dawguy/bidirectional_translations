defmodule BidirectionalTranslations.Translations do
  import Ecto.Query

  alias BidirectionalTranslations.Repo
  alias BidirectionalTranslations.Accounts.Scope
  alias BidirectionalTranslations.Translations.{Article, Session, Attempt}

  # Day offset and direction for auto-scheduled sessions on article creation
  @default_schedule [
    {0, :target_to_english},
    {3, :english_to_target},
    {7, :english_to_target},
    {14, :english_to_target}
  ]

  @doc """
  Returns the total number of sessions in the fixed schedule.
  """
  def total_session_count, do: length(@default_schedule)

  ## Articles

  def list_articles(%Scope{} = scope) do
    Article
    |> where(user_id: ^scope.user.id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @per_page 20

  def list_articles_with_sessions(%Scope{} = scope, page \\ 1) do
    Article
    |> where(user_id: ^scope.user.id)
    |> order_by(desc: :inserted_at)
    |> preload(:sessions)
    |> limit(^@per_page)
    |> offset(^(@per_page * (page - 1)))
    |> Repo.all()
  end

  @doc """
  Returns the total count of articles for a user. Used to determine if there
  are more pages to load.
  """
  def count_articles(%Scope{} = scope) do
    Article
    |> where(user_id: ^scope.user.id)
    |> Repo.aggregate(:count)
  end

  def get_article!(%Scope{} = scope, id) do
    Article
    |> where(user_id: ^scope.user.id, id: ^id)
    |> Repo.one!()
  end

  def create_article(%Scope{} = scope, attrs) do
    Repo.transaction(fn ->
      case %Article{user_id: scope.user.id}
           |> Article.changeset(attrs)
           |> Repo.insert() do
        {:ok, article} ->
          # Only create the first session — subsequent ones appear after each completion
          {day_offset, direction} = hd(@default_schedule)

          %Session{}
          |> Session.changeset(%{
            article_id: article.id,
            user_id: scope.user.id,
            direction: direction,
            scheduled_date: Date.add(Date.utc_today(), day_offset)
          })
          |> Repo.insert!()

          article

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def update_article(%Scope{} = scope, %Article{} = article, attrs) do
    if article.user_id != scope.user.id do
      {:error, :unauthorized}
    else
      article
      |> Article.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_article(%Scope{} = scope, %Article{} = article) do
    if article.user_id != scope.user.id do
      {:error, :unauthorized}
    else
      Repo.delete(article)
    end
  end

  def change_article(%Article{} = article, attrs \\ %{}) do
    Article.changeset(article, attrs)
  end

  ## Sessions

  @doc """
  Returns pending/postponed sessions due on or before `date` (default today).
  Ordered oldest-first so overdue items surface at the top.
  """
  def list_due_sessions(%Scope{} = scope, date \\ Date.utc_today()) do
    Session
    |> where(user_id: ^scope.user.id)
    |> where([s], s.scheduled_date <= ^date)
    |> where([s], s.status in [:pending, :postponed])
    |> order_by(asc: :scheduled_date)
    |> preload(:article)
    |> Repo.all()
  end

  @doc """
  Returns pending/postponed sessions scheduled in the next `days` days after `date`.
  """
  def list_upcoming_sessions(%Scope{} = scope, date \\ Date.utc_today(), days \\ 7) do
    window_end = Date.add(date, days)

    Session
    |> where(user_id: ^scope.user.id)
    |> where([s], s.scheduled_date > ^date and s.scheduled_date <= ^window_end)
    |> where([s], s.status in [:pending, :postponed])
    |> order_by(asc: :scheduled_date)
    |> preload(:article)
    |> Repo.all()
  end

  @doc """
  Returns the single earliest pending/postponed session per article on or after `date`.
  Uses PostgreSQL DISTINCT ON to pick the minimum scheduled_date per article_id.
  Future sessions for the same article are hidden until the earliest one is completed.
  """
  def list_next_sessions(%Scope{} = scope, date \\ Date.utc_today()) do
    Session
    |> where(user_id: ^scope.user.id)
    |> where([s], s.scheduled_date > ^date)
    |> where([s], s.status in [:pending, :postponed])
    |> order_by([s], asc: s.article_id, asc: s.scheduled_date)
    |> distinct([s], s.article_id)
    |> preload(:article)
    |> Repo.all()
  end

  def list_sessions_for_article(%Scope{} = scope, %Article{} = article) do
    Session
    |> where(user_id: ^scope.user.id, article_id: ^article.id)
    |> order_by(asc: :scheduled_date)
    |> preload(:attempt)
    |> Repo.all()
  end

  def get_session!(%Scope{} = scope, id) do
    Session
    |> where(user_id: ^scope.user.id, id: ^id)
    |> preload([:article, :attempt])
    |> Repo.one!()
  end

  def postpone_session(%Session{} = session, new_date) do
    session
    |> Session.changeset(%{scheduled_date: new_date, status: :postponed})
    |> Repo.update()
  end

  def complete_session(%Session{} = session) do
    Repo.transaction(fn ->
      updated =
        session
        |> Session.changeset(%{status: :completed, completed_at: DateTime.utc_now(:second)})
        |> Repo.update!()

      # Auto-schedule the next session if there's one remaining
      complete_count =
        Session
        |> where(article_id: ^session.article_id, status: :completed)
        |> Repo.aggregate(:count)

      scheduled = Enum.at(@default_schedule, complete_count)

      if scheduled do
        {day_offset, direction} = scheduled

        %Session{}
        |> Session.changeset(%{
          article_id: session.article_id,
          user_id: session.user_id,
          direction: direction,
          scheduled_date: Date.add(Date.utc_today(), day_offset)
        })
        |> Repo.insert!()
      end

      updated
    end)
    |> case do
      {:ok, updated} -> {:ok, updated}
      {:error, reason} -> {:error, reason}
    end
  end

  ## Attempts

  @doc """
  Inserts or updates the single attempt for a session.
  Safe to call on every keystroke — uses a DB-level upsert.
  """
  def upsert_attempt(%Session{} = session, body) do
    now = DateTime.utc_now(:second)
    trimmed = String.trim(body)

    %Attempt{}
    |> Attempt.changeset(%{body: trimmed, session_id: session.id})
    |> Repo.insert(
      on_conflict: [set: [body: trimmed, updated_at: now]],
      conflict_target: [:session_id]
    )
  end
end
