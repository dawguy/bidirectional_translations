defmodule BidirectionalTranslationsWeb.UserLive.Registration do
  use BidirectionalTranslationsWeb, :live_view

  alias BidirectionalTranslations.Accounts
  alias BidirectionalTranslations.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-[calc(100vh-65px)] items-center justify-center px-4 py-12">
      <div class="w-full max-w-sm space-y-6">
        <div class="text-center">
          <h1 class="text-2xl font-bold tracking-tight">Create an account</h1>
          <p class="mt-1 text-sm text-base-content/60">
            Start practicing your translations today.
          </p>
        </div>

        <div class="card bg-base-100 border border-base-300 shadow-sm">
          <div class="card-body gap-4 p-6">
            <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                spellcheck="false"
                required
                phx-mounted={JS.focus()}
              />
              <.button phx-disable-with="Creating account..." class="btn btn-primary w-full mt-1">
                Create account
              </.button>
            </.form>
          </div>
        </div>

        <p class="text-center text-sm text-base-content/60">
          Already have an account?
          <.link navigate={~p"/users/log-in"} class="link font-medium">Sign in</.link>
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: BidirectionalTranslationsWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
