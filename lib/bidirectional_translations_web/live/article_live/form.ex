defmodule BidirectionalTranslationsWeb.ArticleLive.Form do
  use BidirectionalTranslationsWeb, :live_view

  alias BidirectionalTranslations.Translations
  alias BidirectionalTranslations.Translations.Article

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:language_options, language_options())
     |> assign(:last_language, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    article = %Article{language: socket.assigns.last_language}

    socket
    |> assign(:page_title, "New Article")
    |> assign(:article, article)
    |> assign(:form, to_form(Translations.change_article(article)))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    article = Translations.get_article!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Article")
    |> assign(:article, article)
    |> assign(:form, to_form(Translations.change_article(article)))
  end

  @impl true
  def handle_event("validate", %{"article" => params}, socket) do
    form =
      socket.assigns.article
      |> Translations.change_article(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"article" => params}, socket) do
    save_article(socket, socket.assigns.live_action, params)
  end

  def handle_event("restore_language", %{"language" => lang}, socket) do
    article = %Article{socket.assigns.article | language: lang}
    form = to_form(Translations.change_article(article))

    {:noreply,
     socket
     |> assign(:last_language, lang)
     |> assign(:article, article)
     |> assign(:form, form)}
  end

  defp save_article(socket, :new, params) do
    case Translations.create_article(socket.assigns.current_scope, params) do
      {:ok, article} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article created. Sessions scheduled for days 0, 3, 7, and 14.")
         |> push_navigate(to: ~p"/articles/#{article}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_article(socket, :edit, params) do
    case Translations.update_article(socket.assigns.current_scope, socket.assigns.article, params) do
      {:ok, article} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article updated.")
         |> push_navigate(to: ~p"/articles/#{article}")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to edit this article.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <h1 class="text-2xl font-bold">{@page_title}</h1>

        <.form
          for={@form}
          phx-change="validate"
          phx-submit="save"
          class="space-y-4"
          id="article-form"
          phx-hook=".RememberLanguage"
        >
          <.article_form_fields form={@form} language_options={@language_options} />

          <div class="flex gap-3 pt-2">
            <.button type="submit" variant="primary" phx-disable-with="Saving...">
              {if @live_action == :new, do: "Create Article", else: "Save Changes"}
            </.button>
            <.link
              navigate={if @live_action == :new, do: ~p"/articles", else: ~p"/articles/#{@article}"}
              class="btn btn-ghost"
            >
              Cancel
            </.link>
          </div>
        </.form>
      </div>
    </Layouts.app>

    <script
      :type={Phoenix.LiveView.ColocatedHook}
      name=".RememberLanguage"
      id="remember-language-hook"
      phx-update="ignore"
    >
      export default {
        mounted() {
          // Restore last selected language
          const stored = localStorage.getItem("last_language")
          if (stored) this.pushEvent("restore_language", {language: stored})

          // Auto-save language on change for next time
          const select = this.el.querySelector("select[name='article[language]']")
          if (select) {
            select.addEventListener("change", e => {
              localStorage.setItem("last_language", e.target.value)
            })
          }
        }
      }
    </script>
    """
  end
end
