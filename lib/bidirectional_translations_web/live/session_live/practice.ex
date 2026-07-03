defmodule BidirectionalTranslationsWeb.SessionLive.Practice do
  use BidirectionalTranslationsWeb, :live_view

  alias BidirectionalTranslations.Translations

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    scope = socket.assigns.current_scope
    session = Translations.get_session!(scope, id)
    attempt_body = if session.attempt, do: session.attempt.body, else: ""
    mode = if session.status == :completed, do: :review, else: :practice

    {:ok,
     socket
     |> assign(:page_title, session.article.title)
     |> assign(:session, session)
     |> assign(:attempt_body, attempt_body)
     |> assign(:peek, false)
     |> assign(:mode, mode)}
  end

  @impl true
  def handle_event("save_attempt", %{"body" => body}, socket) do
    if String.trim(body) != "" do
      Translations.upsert_attempt(socket.assigns.session, body)
    end

    {:noreply, assign(socket, :attempt_body, body)}
  end

  def handle_event("toggle_peek", _params, socket) do
    {:noreply, assign(socket, :peek, !socket.assigns.peek)}
  end

  def handle_event("complete", _params, socket) do
    session = socket.assigns.session
    body = socket.assigns.attempt_body

    if String.trim(body) != "" do
      {:ok, _} = Translations.upsert_attempt(session, body)
    end

    {:ok, _} = Translations.complete_session(session)
    fresh_session = Translations.get_session!(socket.assigns.current_scope, session.id)

    {:noreply,
     socket
     |> assign(:session, fresh_session)
     |> assign(:mode, :review)
     |> assign(:peek, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} max_width="max-w-7xl">
      <div :if={@mode == :practice} class="space-y-6">
        <div class="flex items-start justify-between gap-4">
          <div>
            <.link
              navigate={~p"/articles/#{@session.article}"}
              class="text-sm link link-hover text-base-content/60"
            >
              ← {@session.article.title}
            </.link>
            <h1 class="text-xl font-bold mt-1">
              {direction_label(@session.direction, @session.article.language)}
            </h1>
          </div>
          <span class="badge badge-neutral shrink-0">
            {language_name(@session.article.language)}
          </span>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">
          <div>
            <p class="text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-2">
              {source_label(@session)}
            </p>
            <div class="bg-base-200 rounded-lg p-4 text-sm leading-relaxed whitespace-pre-wrap min-h-96">
              {source_text(@session)}
            </div>
          </div>

          <div class="space-y-3">
            <p class="text-xs font-semibold uppercase tracking-wider text-base-content/50">
              Your translation — {answer_label(@session)}
            </p>
            <form phx-change="save_attempt">
              <textarea
                name="body"
                phx-debounce="800"
                class="textarea textarea-bordered w-full min-h-96 text-sm leading-relaxed font-sans"
                placeholder="Start typing your translation..."
              >{@attempt_body}</textarea>
            </form>
            <div class="flex items-center justify-between">
              <button phx-click="toggle_peek" class="btn btn-ghost btn-sm">
                {if @peek, do: "Hide peek", else: "Peek"}
              </button>
              <button
                phx-click="complete"
                phx-confirm="Mark this session as complete?"
                phx-disable-with="Saving..."
                class="btn btn-primary btn-sm"
              >
                Mark Complete
              </button>
            </div>
          </div>
        </div>

        <div :if={@peek} class="mt-2">
          <div class="divider text-xs uppercase tracking-wider opacity-50">
            Professional translation
          </div>
          <div class="bg-base-200 rounded-lg p-4 text-sm leading-relaxed whitespace-pre-wrap">
            {answer_text(@session)}
          </div>
        </div>
      </div>

      <div :if={@mode == :review} class="space-y-8">
        <div>
          <div class="flex items-center gap-3 mb-1">
            <span class="badge badge-success">Complete</span>
            <.link
              navigate={~p"/articles/#{@session.article}"}
              class="text-sm link link-hover text-base-content/60"
            >
              {@session.article.title}
            </.link>
          </div>
          <h1 class="text-xl font-bold">
            {direction_label(@session.direction, @session.article.language)} — Review
          </h1>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <p class="text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-2">
              My draft — {answer_label(@session)}
            </p>
            <div class="bg-base-200 rounded-lg p-4 text-sm leading-relaxed whitespace-pre-wrap min-h-48">
              {if @session.attempt, do: @session.attempt.body, else: "(no attempt recorded)"}
            </div>
          </div>
          <div>
            <p class="text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-2">
              {answer_label(@session)} — professional
            </p>
            <div class="bg-base-100 border border-base-300 rounded-lg p-4 text-sm leading-relaxed whitespace-pre-wrap min-h-48">
              {answer_text(@session)}
            </div>
          </div>
          <div>
            <p class="text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-2">
              {source_label(@session)} — source
            </p>
            <div class="bg-base-100 border border-base-300 rounded-lg p-4 text-sm leading-relaxed whitespace-pre-wrap min-h-48">
              {source_text(@session)}
            </div>
          </div>
        </div>

        <div class="flex gap-3">
          <.link navigate={~p"/articles/#{@session.article}"} class="btn btn-primary btn-sm">
            Back to Article
          </.link>
          <.link navigate={~p"/dashboard"} class="btn btn-ghost btn-sm">
            Dashboard
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
