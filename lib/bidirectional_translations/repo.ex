defmodule BidirectionalTranslations.Repo do
  use Ecto.Repo,
    otp_app: :bidirectional_translations,
    adapter: Ecto.Adapters.Postgres,
    pool_size: 10

  # Only override with DATABASE_URL in production (dev/test configs are set in config/*.exs)
  def init(_type, config) do
    if url = System.get_env("DATABASE_URL") do
      {:ok, Keyword.put(config, :url, url)}
    else
      {:ok, config}
    end
  end
end
