defmodule BidirectionalTranslationsWeb.ArticleComponents do
  @moduledoc """
  Domain-specific components for articles, sessions, and library views.

  Extracted from LiveView templates to eliminate duplication across
  ArticleLive, LibraryLive, and DashboardLive.
  """
  use Phoenix.Component

  import BidirectionalTranslationsWeb.CoreComponents
  import BidirectionalTranslationsWeb.TranslationHelpers

  # -- Article Form Fields --------------------------------------------------

  @doc """
  Shared form fields for creating/editing articles (personal or library).

  Renders: title, language select, source/reader URLs, and dual text areas
  for English and target language text.
  """
  attr :form, Phoenix.HTML.Form, required: true, doc: "the form struct"
  attr :language_options, :list, required: true, doc: "options for language select"

  def article_form_fields(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="md:col-span-2">
        <.input field={@form[:title]} label="Title" placeholder="Article title" />
      </div>
      <.input
        field={@form[:language]}
        type="select"
        label="Target Language"
        options={@language_options}
        prompt="Select a language"
      />
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <.input
        field={@form[:source_url]}
        label="Source URL (optional)"
        placeholder="https://..."
      />
      <.input
        field={@form[:reader_url]}
        label="Reader URL (optional)"
        placeholder="https://www.lingq.com/... or https://kimchi-reader.app/..."
      />
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <.input
        field={@form[:english_text]}
        type="textarea"
        label="English Text"
        rows="18"
        placeholder="Paste the English version here..."
      />
      <.input
        field={@form[:target_text]}
        type="textarea"
        label="Target Language Text"
        rows="18"
        placeholder="Paste the target language version here..."
      />
    </div>
    """
  end

  # -- Article Text Preview -------------------------------------------------

  @doc """
  Side-by-side preview of English and target language text.

  Used in library cards (clamped to 3 lines) and article detail pages (full text).
  """
  attr :english_text, :string, required: true
  attr :target_text, :string, required: true
  attr :language_code, :string, required: true
  attr :clamped, :boolean, default: false, doc: "whether to line-clamp the text"
  attr :class, :any, default: nil, doc: "additional CSS classes for the grid container"
  attr :english_label, :string, default: "EN", doc: "label for the English column"
  attr :target_label, :string, default: nil, doc: "label for the target language column"

  def article_text_preview(assigns) do
    target_label = assigns.target_label || String.upcase(assigns.language_code)
    assigns = assign(assigns, :target_label, target_label)

    ~H"""
    <div class={["grid grid-cols-1 md:grid-cols-2 gap-3", @class]}>
      <div class={[
        "bg-base-100 rounded p-3 text-sm leading-relaxed whitespace-pre-wrap",
        @clamped && "line-clamp-3 text-xs"
      ]}>
        <span class="font-semibold text-base-content/50 uppercase tracking-wider">
          {@english_label}
        </span>
        <span class="ml-2">{@english_text}</span>
      </div>
      <div class={[
        "bg-base-100 rounded p-3 text-sm leading-relaxed whitespace-pre-wrap",
        @clamped && "line-clamp-3 text-xs"
      ]}>
        <span class="font-semibold text-base-content/50 uppercase tracking-wider">
          {@target_label}
        </span>
        <span class="ml-2">{@target_text}</span>
      </div>
    </div>
    """
  end

  # -- Session Card ---------------------------------------------------------

  @doc """
  Displays a practice session row with status, direction, date, and action buttons.

  Action area is rendered via slots so each page (article show, dashboard) can
  provide its own buttons.
  """
  attr :session, :map, required: true
  attr :target_language, :string, required: true, doc: "language code for direction labels"

  attr :variant, :string,
    default: "default",
    values: ~w(default prominent),
    doc: "visual variant: default (bordered) or prominent (bg-base-200 shadow-sm)"

  attr :show_article_title, :boolean,
    default: true,
    doc: "whether to show the article title (disable on article detail pages)"

  slot :status_badges,
    doc: "additional badges after the status badge (e.g. overdue, adoption progress)"

  slot :actions, doc: "action buttons for this session"

  slot :expandable, doc: "expandable content revealed on toggle (e.g. attempt preview)"

  def session_card(assigns) do
    ~H"""
    <div class={[
      "card",
      card_variant_class(@variant)
    ]}>
      <div class="card-body p-4 py-3 gap-0">
        <p
          :if={@show_article_title}
          class="font-semibold truncate mb-1"
        >
          {@session.article.title}
        </p>
        <div class="flex items-center justify-between gap-4">
          <div class="flex items-center gap-3 flex-wrap min-w-0">
            <span class={[
              "badge badge-sm",
              session_status_class(@session.status)
            ]}>
              {@session.status}
            </span>
            {render_slot(@status_badges)}
            <span class="text-sm font-medium">
              {direction_label(@session.direction, @target_language)}
            </span>
            <span class="text-sm text-base-content/60">{@session.scheduled_date}</span>
          </div>
          <div :if={@actions != []} class="flex gap-2 shrink-0">
            {render_slot(@actions)}
          </div>
        </div>

        <div :if={@expandable != []}>
          {render_slot(@expandable)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Compact session card variant for the dashboard "Coming Up" section.
  """
  attr :session, :map, required: true

  def session_compact_card(assigns) do
    ~H"""
    <div class="card bg-base-100 border border-base-300">
      <div class="card-body p-4 py-3">
        <div class="flex items-center justify-between gap-4">
          <div class="min-w-0">
            <span class="font-medium truncate">{@session.article.title}</span>
            <div class="text-sm text-base-content/70 flex flex-wrap gap-x-3 mt-0.5">
              <span>{language_name(@session.article.language)}</span>
              <span>
                {direction_label(@session.direction, @session.article.language)}
              </span>
              <span>{@session.scheduled_date}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # -- Helpers --------------------------------------------------------------

  defp card_variant_class("prominent"), do: "bg-base-200 shadow-sm"
  defp card_variant_class(_), do: "bg-base-100 border border-base-300"

  defp session_status_class(:pending), do: "badge-warning"
  defp session_status_class(:completed), do: "badge-success"
  defp session_status_class(:postponed), do: "badge-info"
end
