defmodule BidirectionalTranslationsWeb.LibraryLive.Index do
  use BidirectionalTranslationsWeb, :live_view

  alias BidirectionalTranslations.Library

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    {library_articles, adoptions, has_more} =
      Library.list_library_articles_with_adoption(scope, 1)

    {:ok,
     socket
     |> assign(:page_title, "Library")
     |> assign(:library_articles, library_articles)
     |> assign(:adoptions, adoptions)
     |> assign(:page, 1)
     |> assign(:has_more, has_more)}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    scope = socket.assigns.current_scope
    next_page = socket.assigns.page + 1

    {new_articles, new_adoptions, has_more} =
      Library.list_library_articles_with_adoption(scope, next_page)

    {:noreply,
     socket
     |> assign(:library_articles, socket.assigns.library_articles ++ new_articles)
     |> assign(:adoptions, Map.merge(socket.assigns.adoptions, new_adoptions))
     |> assign(:page, next_page)
     |> assign(:has_more, has_more)}
  end

  def handle_event("adopt", %{"id" => id}, socket) do
    library_article = Library.get_library_article!(id)

    case Library.adopt_library_article(socket.assigns.current_scope, library_article) do
      {:ok, _article} ->
        scope = socket.assigns.current_scope

        {library_articles, adoptions, has_more} =
          Library.list_library_articles_with_adoption(scope, 1)

        {:noreply,
         socket
         |> put_flash(
           :info,
           "\"#{library_article.title}\" added to your articles. Sessions scheduled for days 0, 3, 7, and 14."
         )
         |> assign(:library_articles, library_articles)
         |> assign(:adoptions, adoptions)
         |> assign(:page, 1)
         |> assign(:has_more, has_more)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not add article.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold">Library</h1>
            <p class="text-sm text-base-content/60 mt-1">
              Browse shared articles. Add ones you want to study.
            </p>
          </div>
          <.link navigate={~p"/library/new"} class="btn btn-primary btn-sm">
            + Add to Library
          </.link>
        </div>

        <.empty_state :if={@library_articles == []}>
          <p>The library is empty.</p>
          <p class="mt-1">
            <.link navigate={~p"/library/new"} class="link link-hover">
              Add the first article
            </.link>
            {" "}to get started.
          </p>
        </.empty_state>

        <div class="space-y-3">
          <div :for={article <- @library_articles} class="card bg-base-200 shadow-sm">
            <div class="card-body p-4">
              <div class="flex items-start justify-between gap-4">
                <div class="min-w-0 flex-1">
                  <div class="flex items-center gap-2 mb-1 flex-wrap">
                    <h2 class="font-semibold">{article.title}</h2>
                    <span class="badge badge-neutral badge-sm">
                      {language_name(article.language)}
                    </span>
                    <%= if adoption = @adoptions[article.id] do %>
                      <span class={[
                        "badge badge-sm",
                        Library.adoption_badge_class(adoption)
                      ]}>
                        {Library.adoption_label(adoption)}
                      </span>
                    <% end %>
                  </div>

                  <div class="flex items-center gap-3 text-sm text-base-content/60 flex-wrap">
                    <span :if={article.source_url}>
                      <a
                        href={external_url(article.source_url)}
                        target="_blank"
                        rel="noopener"
                        class="link link-hover"
                      >
                        Source ↗
                      </a>
                    </span>
                    <span :if={article.reader_url}>
                      <a
                        href={external_url(article.reader_url)}
                        target="_blank"
                        rel="noopener"
                        class="link link-hover"
                      >
                        Reader ↗
                      </a>
                    </span>
                    <span :if={article.submitted_by_user}>
                      Added by {article.submitted_by_user.email}
                    </span>
                  </div>

                  <.article_text_preview
                    english_text={article.english_text}
                    target_text={article.target_text}
                    language_code={article.language}
                    clamped={true}
                    class="mt-2"
                  />
                </div>

                <div class="flex gap-2 shrink-0">
                  <.link
                    navigate={~p"/library/#{article}/edit"}
                    class="btn btn-ghost btn-sm"
                  >
                    Edit
                  </.link>
                  <%= if adoption = @adoptions[article.id] do %>
                    <.link
                      navigate={~p"/articles/#{adoption.article_id}"}
                      class="btn btn-ghost btn-sm"
                    >
                      View
                    </.link>
                  <% else %>
                    <button
                      phx-click="adopt"
                      phx-value-id={article.id}
                      class="btn btn-primary btn-sm"
                    >
                      Add to My Articles
                    </button>
                  <% end %>
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
end
