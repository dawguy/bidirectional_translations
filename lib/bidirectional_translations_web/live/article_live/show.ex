defmodule BidirectionalTranslationsWeb.ArticleLive.Show do
  use BidirectionalTranslationsWeb, :live_view

  alias BidirectionalTranslations.Translations

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    scope = socket.assigns.current_scope
    article = Translations.get_article!(scope, id)
    sessions = Translations.list_sessions_for_article(scope, article)

    {:ok,
     socket
     |> assign(:page_title, article.title)
     |> assign(:article, article)
     |> assign(:sessions, sessions)
     |> assign(:expanded_attempt_id, nil)}
  end

  @impl true
  def handle_event("toggle_attempt", %{"id" => id}, socket) do
    id = String.to_integer(id)
    expanded = if socket.assigns.expanded_attempt_id == id, do: nil, else: id
    {:noreply, assign(socket, :expanded_attempt_id, expanded)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <div class="flex items-start justify-between gap-4">
          <div>
            <h1 class="text-2xl font-bold">{@article.title}</h1>
            <div class="flex items-center gap-3 mt-2">
              <span class="badge badge-neutral">{language_name(@article.language)}</span>
              <a
                :if={@article.source_url}
                href={@article.source_url}
                target="_blank"
                rel="noopener"
                class="link link-hover text-sm"
              >
                Source ↗
              </a>
            </div>
          </div>
          <.link navigate={~p"/articles/#{@article}/edit"} class="btn btn-ghost btn-sm">
            Edit
          </.link>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h2 class="text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-2">
              English
            </h2>
            <div class="bg-base-200 rounded-lg p-4 text-sm leading-relaxed whitespace-pre-wrap">
              {@article.english_text}
            </div>
          </div>
          <div>
            <h2 class="text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-2">
              {language_name(@article.language)}
            </h2>
            <div class="bg-base-200 rounded-lg p-4 text-sm leading-relaxed whitespace-pre-wrap">
              {@article.target_text}
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-lg font-semibold mb-3">Practice Sessions</h2>
          <div class="space-y-2">
            <div :for={session <- @sessions} class="card bg-base-100 border border-base-300">
              <div class="card-body p-4 py-3 gap-0">
                <div class="flex items-center justify-between gap-4">
                  <div class="flex items-center gap-3 flex-wrap min-w-0">
                    <span class={["badge badge-sm", status_badge_class(session.status)]}>
                      {session.status}
                    </span>
                    <span class="text-sm font-medium">
                      {direction_label(session.direction, @article.language)}
                    </span>
                    <span class="text-sm text-base-content/60">{session.scheduled_date}</span>
                  </div>
                  <div class="flex gap-2 shrink-0">
                    <.link
                      :if={session.status != :completed}
                      navigate={~p"/sessions/#{session.id}/practice"}
                      class="btn btn-primary btn-xs"
                    >
                      {if session.status == :pending, do: "Start", else: "Resume"}
                    </.link>
                    <button
                      :if={session.status == :completed and session.attempt != nil}
                      phx-click="toggle_attempt"
                      phx-value-id={session.id}
                      class="btn btn-ghost btn-xs"
                    >
                      {if @expanded_attempt_id == session.id, do: "Hide", else: "View attempt"}
                    </button>
                  </div>
                </div>

                <div
                  :if={@expanded_attempt_id == session.id and session.attempt}
                  class="mt-3 pt-3 border-t border-base-300"
                >
                  <p class="text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-2">
                    Your attempt
                  </p>
                  <div class="bg-base-200 rounded p-3 text-sm leading-relaxed whitespace-pre-wrap">
                    {session.attempt.body}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp status_badge_class(:pending), do: "badge-warning"
  defp status_badge_class(:completed), do: "badge-success"
  defp status_badge_class(:postponed), do: "badge-info"
end
