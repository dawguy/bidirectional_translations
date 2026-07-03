defmodule BidirectionalTranslations do
  @moduledoc """
  BidirectionalTranslations keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @supported_languages ~w(de ko fr es ja zh it pt ru)

  @doc "Returns the list of supported language codes."
  def supported_languages, do: @supported_languages
end
