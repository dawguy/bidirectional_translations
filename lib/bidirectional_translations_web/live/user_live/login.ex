defmodule BidirectionalTranslationsWeb.UserLive.Login do
  use BidirectionalTranslationsWeb, :live_view

  alias BidirectionalTranslations.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-[calc(100vh-65px)] items-center justify-center px-4 py-12">
      <div class="w-full max-w-sm space-y-6">
        <div class="text-center">
          <h1 class="text-2xl font-bold tracking-tight">
            {if @current_scope, do: "Verify your identity", else: "Sign in"}
          </h1>
          <p class="mt-1 text-sm text-base-content/60">
            {if @current_scope,
              do: "Re-authenticate to continue.",
              else: "Welcome back. Enter your details below."}
          </p>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info py-2 text-sm">
          <.icon name="hero-information-circle" class="size-4 shrink-0" />
          <span>
            Local mail adapter active — <.link href="/dev/mailbox" class="underline">view mailbox</.link>.
          </span>
        </div>

        <div class="card bg-base-100 border border-base-300 shadow-sm">
          <div class="card-body gap-4 p-6">
            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                spellcheck="false"
                required
                phx-mounted={JS.focus()}
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
                spellcheck="false"
              />
              <.input field={@form[:remember_me]} type="checkbox" label="Stay signed in" />
              <.button class="btn btn-primary w-full mt-1">
                Sign in
              </.button>
            </.form>

            <div class="divider my-0 text-xs text-base-content/40">or</div>

            <.form
              :let={f}
              for={@form}
              id="login_form_magic"
              action={~p"/users/log-in"}
              phx-submit="submit_magic"
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                spellcheck="false"
                required
              />
              <.button class="btn btn-ghost btn-sm w-full mt-2">
                Send magic link
              </.button>
            </.form>
          </div>
        </div>

        <p :if={!@current_scope} class="text-center text-sm text-base-content/60">
          Don't have an account?
          <.link navigate={~p"/users/register"} class="link font-medium">Sign up</.link>
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    {:noreply,
     socket
     |> put_flash(
       :info,
       "If your email is in our system, you will receive a login link shortly."
     )
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:bidirectional_translations, BidirectionalTranslations.Mailer)[:adapter] ==
      Swoosh.Adapters.Local
  end
end
