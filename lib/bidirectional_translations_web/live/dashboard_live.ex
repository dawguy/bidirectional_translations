defmodule BidirectionalTranslationsWeb.DashboardLive do
  use BidirectionalTranslationsWeb, :live_view

  alias BidirectionalTranslations.Translations

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    scope = socket.assigns.current_scope

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:today, today)
     |> assign(:due_sessions, Translations.list_due_sessions(scope, today))
     |> assign(:upcoming_sessions, Translations.list_upcoming_sessions(scope, today))
     |> assign(:postponing_id, nil)}
  end

  @impl true
  def handle_event("postpone_open", %{"id" => id}, socket) do
    {:noreply, assign(socket, :postponing_id, String.to_integer(id))}
  end

  def handle_event("postpone_cancel", _params, socket) do
    {:noreply, assign(socket, :postponing_id, nil)}
  end

  def handle_event("postpone_submit", %{"session_id" => id, "date" => date_str}, socket) do
    with {:ok, new_date} <- Date.from_iso8601(date_str),
         :gt <- Date.compare(new_date, socket.assigns.today),
         session <- Translations.get_session!(socket.assigns.current_scope, String.to_integer(id)),
         {:ok, _} <- Translations.postpone_session(session, new_date) do
      scope = socket.assigns.current_scope
      today = socket.assigns.today

      {:noreply,
       socket
       |> assign(:due_sessions, Translations.list_due_sessions(scope, today))
       |> assign(:upcoming_sessions, Translations.list_upcoming_sessions(scope, today))
       |> assign(:postponing_id, nil)
       |> put_flash(:info, "Session postponed to #{new_date}.")}
    else
      :eq -> {:noreply, put_flash(socket, :error, "Please choose a future date.")}
      :lt -> {:noreply, put_flash(socket, :error, "Please choose a future date.")}
      _ -> {:noreply, put_flash(socket, :error, "Could not postpone session.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-bold">Dashboard</h1>
          <span class="text-sm text-base-content/60">{Calendar.strftime(@today, "%B %-d, %Y")}</span>
        </div>

        <section>
          <h2 class="text-lg font-semibold mb-3">Due Now</h2>
          <div :if={@due_sessions == []} class="text-base-content/60 py-4">
            You're all caught up — nothing due today.
          </div>
          <div class="space-y-3">
            <div :for={session <- @due_sessions} class="card bg-base-200 shadow-sm">
              <div class="card-body p-4 gap-2">
                <div class="flex items-start justify-between gap-4">
                  <div class="min-w-0">
                    <div class="flex items-center gap-2 mb-1 flex-wrap">
                      <h3 class="font-semibold truncate">{session.article.title}</h3>
                      <span :if={overdue?(session, @today)} class="badge badge-error badge-sm shrink-0">
                        Overdue
                      </span>
                    </div>
                    <div class="text-sm text-base-content/70 flex flex-wrap gap-x-3 gap-y-1">
                      <span>{language_name(session.article.language)}</span>
                      <span>{direction_label(session.direction, session.article.language)}</span>
                      <span>Scheduled {session.scheduled_date}</span>
                    </div>
                  </div>
                  <div class="flex gap-2 shrink-0">
                    <.link navigate={~p"/sessions/#{session.id}/practice"} class="btn btn-primary btn-sm">
                      Start
                    </.link>
                    <button
                      phx-click="postpone_open"
                      phx-value-id={session.id}
                      class="btn btn-ghost btn-sm"
                    >
                      Postpone
                    </button>
                  </div>
                </div>

                <div :if={@postponing_id == session.id} class="pt-3 border-t border-base-300">
                  <form phx-submit="postpone_submit" class="flex flex-wrap items-center gap-3">
                    <input type="hidden" name="session_id" value={session.id} />
                    <label class="text-sm font-medium">New date:</label>
                    <input
                      type="date"
                      name="date"
                      min={Date.to_string(Date.add(@today, 1))}
                      value={Date.to_string(Date.add(@today, 1))}
                      class="input input-bordered input-sm"
                    />
                    <button type="submit" class="btn btn-primary btn-sm">Confirm</button>
                    <button type="button" phx-click="postpone_cancel" class="btn btn-ghost btn-sm">
                      Cancel
                    </button>
                  </form>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section :if={@upcoming_sessions != []}>
          <h2 class="text-lg font-semibold mb-3">Coming Up</h2>
          <div class="space-y-2">
            <div
              :for={session <- @upcoming_sessions}
              class="card bg-base-100 border border-base-300"
            >
              <div class="card-body p-4 py-3">
                <div class="flex items-center justify-between gap-4">
                  <div class="min-w-0">
                    <span class="font-medium truncate">{session.article.title}</span>
                    <div class="text-sm text-base-content/70 flex flex-wrap gap-x-3 mt-0.5">
                      <span>{language_name(session.article.language)}</span>
                      <span>{direction_label(session.direction, session.article.language)}</span>
                      <span>{session.scheduled_date}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  defp overdue?(session, today), do: Date.compare(session.scheduled_date, today) == :lt

  defp direction_label(:target_to_english, _lang), do: "→ English"
  defp direction_label(:english_to_target, lang), do: "→ #{language_name(lang)}"

  defp language_name("de"), do: "German"
  defp language_name("ko"), do: "Korean"
  defp language_name("fr"), do: "French"
  defp language_name("es"), do: "Spanish"
  defp language_name("ja"), do: "Japanese"
  defp language_name("zh"), do: "Chinese"
  defp language_name("it"), do: "Italian"
  defp language_name("pt"), do: "Portuguese"
  defp language_name("ru"), do: "Russian"
  defp language_name(code), do: code
end
