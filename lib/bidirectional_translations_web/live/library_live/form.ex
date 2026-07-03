defmodule BidirectionalTranslationsWeb.LibraryLive.Form do
  use BidirectionalTranslationsWeb, :live_view

  alias BidirectionalTranslations.Library
  alias BidirectionalTranslations.Library.Article, as: LibraryArticle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    article = %LibraryArticle{}

    socket
    |> assign(:page_title, "Add to Library")
    |> assign(:article, article)
    |> assign(:form, to_form(LibraryArticle.changeset(article, %{}), as: :library_article))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    article = Library.get_library_article!(id)

    socket
    |> assign(:page_title, "Edit Library Article")
    |> assign(:article, article)
    |> assign(:form, to_form(Library.change_library_article(article), as: :library_article))
  end

  @impl true
  def handle_event("validate", %{"library_article" => params}, socket) do
    form =
      socket.assigns.article
      |> LibraryArticle.changeset(params)
      |> Map.put(:action, :validate)
      |> to_form(as: :library_article)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"library_article" => params}, socket) do
    save_article(socket, socket.assigns.live_action, params)
  end

  defp save_article(socket, :new, params) do
    scope = socket.assigns.current_scope

    case Library.create_library_article(params, scope.user.id) do
      {:ok, _article} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article added to the library.")
         |> push_navigate(to: ~p"/library")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :library_article))}
    end
  end

  defp save_article(socket, :edit, params) do
    case Library.update_library_article(socket.assigns.article, params) do
      {:ok, _article} ->
        {:noreply,
         socket
         |> put_flash(:info, "Article updated.")
         |> push_navigate(to: ~p"/library")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :library_article))}
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
          id="library-article-form"
        >
          <.article_form_fields form={@form} language_options={language_options()} />

          <div class="flex gap-3 pt-2">
            <.button type="submit" variant="primary" phx-disable-with="Saving...">
              {if @live_action == :new, do: "Add to Library", else: "Save Changes"}
            </.button>
            <.link navigate={~p"/library"} class="btn btn-ghost">
              Cancel
            </.link>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
