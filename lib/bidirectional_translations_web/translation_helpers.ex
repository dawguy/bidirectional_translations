defmodule BidirectionalTranslationsWeb.TranslationHelpers do
  alias BidirectionalTranslations

  @doc "Returns the list of supported language codes."
  defdelegate supported_languages, to: BidirectionalTranslations

  @doc """
  Ensures a URL has a protocol for use as an external link.
  Prepends `https://` if no protocol is present.
  """
  def external_url(nil), do: nil

  def external_url(url) do
    if String.starts_with?(url, ~w(http:// https://)), do: url, else: "https://#{url}"
  end

  def language_name("de"), do: "German"
  def language_name("ko"), do: "Korean"
  def language_name("fr"), do: "French"
  def language_name("es"), do: "Spanish"
  def language_name("ja"), do: "Japanese"
  def language_name("zh"), do: "Chinese"
  def language_name("it"), do: "Italian"
  def language_name("pt"), do: "Portuguese"
  def language_name("ru"), do: "Russian"
  def language_name(code), do: code

  def direction_label(:target_to_english, _lang), do: "→ English"
  def direction_label(:english_to_target, lang), do: "→ #{language_name(lang)}"

  @doc """
  Returns the source text for a session based on its direction.
  """
  def source_text(%{direction: :target_to_english, article: article}), do: article.target_text
  def source_text(%{direction: :english_to_target, article: article}), do: article.english_text

  @doc """
  Returns the answer/professional translation text for a session.
  """
  def answer_text(%{direction: :target_to_english, article: article}), do: article.english_text
  def answer_text(%{direction: :english_to_target, article: article}), do: article.target_text

  @doc """
  Returns the label for the source language in a session.
  """
  def source_label(%{direction: :target_to_english, article: article}),
    do: language_name(article.language)

  def source_label(%{direction: :english_to_target}), do: "English"

  @doc """
  Returns the label for the answer/target language in a session.
  """
  def answer_label(%{direction: :target_to_english}), do: "English"

  def answer_label(%{direction: :english_to_target, article: article}),
    do: language_name(article.language)

  def language_options do
    BidirectionalTranslations.supported_languages()
    |> Enum.map(fn code -> {language_name(code), code} end)
  end
end
