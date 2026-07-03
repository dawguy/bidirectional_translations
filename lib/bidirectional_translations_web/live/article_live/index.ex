defmodule BidirectionalTranslationsWeb.ArticleLive.Index do
  use BidirectionalTranslationsWeb, :live_view

  alias BidirectionalTranslations.Translations

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    {:ok,
     socket
     |> assign(:page_title, "Articles")
     |> assign(:articles, Translations.list_articles_with_sessions(scope, 1))
     |> assign(:page, 1)
     |> assign(:has_more, Translations.count_articles(scope) > @per_page)
     |> assign(:deleting_id, nil)}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    scope = socket.assigns.current_scope
    next_page = socket.assigns.page + 1
    new_articles = Translations.list_articles_with_sessions(scope, next_page)

    {:noreply,
     socket
     |> assign(:articles, socket.assigns.articles ++ new_articles)
     |> assign(:page, next_page)
     |> assign(:has_more, Translations.count_articles(scope) > next_page * @per_page)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    article = Translations.get_article!(socket.assigns.current_scope, id)

    case Translations.delete_article(socket.assigns.current_scope, article) do
      {:ok, _} ->
        scope = socket.assigns.current_scope

        {:noreply,
         socket
         |> put_flash(:info, "Article deleted.")
         |> assign(:deleting_id, nil)
         |> assign(:articles, Translations.list_articles_with_sessions(scope, 1))
         |> assign(:page, 1)
         |> assign(:has_more, Translations.count_articles(scope) > @per_page)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete article.")}
    end
  end

  def handle_event("open_delete_confirm", %{"id" => id}, socket) do
    {:noreply, assign(socket, :deleting_id, String.to_integer(id))}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :deleting_id, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-bold">Articles</h1>
          <.link navigate={~p"/articles/new"} class="btn btn-primary btn-sm">
            + New Article
          </.link>
        </div>

        <.empty_state :if={@articles == []}>
          <p>No articles yet.</p>
          <p class="mt-1">Add your first article to get started.</p>
        </.empty_state>

        <div class="space-y-3">
          <div :for={article <- @articles} class="card bg-base-200 shadow-sm">
            <div class="card-body p-4">
              <div class="flex items-start justify-between gap-4">
                <div class="min-w-0">
                  <div class="flex items-center gap-2 mb-1 flex-wrap">
                    <h2 class="font-semibold">{article.title}</h2>
                    <span class="badge badge-neutral badge-sm">
                      {language_name(article.language)}
                    </span>
                  </div>
                  <p class="text-sm text-base-content/60">
                    {session_progress(article.sessions)} sessions complete
                  </p>
                </div>
                <div class="flex gap-2 shrink-0">
                  <.link navigate={~p"/articles/#{article}"} class="btn btn-ghost btn-sm">
                    View
                  </.link>
                  <.link navigate={~p"/articles/#{article}/edit"} class="btn btn-ghost btn-sm">
                    Edit
                  </.link>
                  <button
                    phx-click="open_delete_confirm"
                    phx-value-id={article.id}
                    class="btn btn-ghost btn-sm text-error"
                  >
                    Delete
                  </button>
                </div>
              </div>

              <%!-- Inline delete confirmation --%>
              <div :if={@deleting_id == article.id} class="mt-4 pt-4 border-t border-base-300">
                <p class="text-sm mb-3">
                  Delete <strong>{article.title}</strong>
                  and all its practice sessions? <br class="hidden sm:inline" />
                  <span class="text-error">This cannot be undone.</span>
                </p>
                <div class="flex gap-2">
                  <button phx-click="delete" phx-value-id={article.id} class="btn btn-error btn-sm">
                    Yes, delete
                  </button>
                  <button phx-click="cancel_delete" class="btn btn-ghost btn-sm">
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div :if={@has_more} class="text-center pt-2">
          <button phx-click="load_more" class="btn btn-ghost btn-sm">
            Load more articles
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp session_progress(sessions) do
    completed = Enum.count(sessions, &(&1.status == :completed))
    "#{completed}/#{Translations.total_session_count()}"
  end
end
