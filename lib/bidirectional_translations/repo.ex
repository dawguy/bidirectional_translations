defmodule BidirectionalTranslations.Repo do
  use Ecto.Repo,
    otp_app: :bidirectional_translations,
    adapter: Ecto.Adapters.Postgres
end
