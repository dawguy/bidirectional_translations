defmodule BidirectionalTranslationsWeb.TranslationHelpers do
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

  def language_options do
    [
      {"German", "de"},
      {"Korean", "ko"},
      {"French", "fr"},
      {"Spanish", "es"},
      {"Japanese", "ja"},
      {"Chinese", "zh"},
      {"Italian", "it"},
      {"Portuguese", "pt"},
      {"Russian", "ru"}
    ]
  end
end
