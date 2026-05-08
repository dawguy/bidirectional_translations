defmodule BidirectionalTranslations.Mailer.RateLimitedAdapter do
  @behaviour Swoosh.Adapter

  alias BidirectionalTranslations.Mailer.RateLimiter

  @impl true
  def validate_config(config) do
    case Keyword.fetch(config, :inner_adapter) do
      {:ok, inner_adapter} -> inner_adapter.validate_config(config)
      :error -> {:error, "RateLimitedAdapter requires :inner_adapter to be set"}
    end
  end

  @impl true
  def deliver(email, config) do
    inner_adapter = Keyword.fetch!(config, :inner_adapter)

    case RateLimiter.check_and_increment() do
      :ok -> inner_adapter.deliver(email, config)
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def deliver_many(emails, config) do
    inner_adapter = Keyword.fetch!(config, :inner_adapter)

    case RateLimiter.check_and_increment_by(length(emails)) do
      :ok -> inner_adapter.deliver_many(emails, config)
      {:error, reason} -> {:error, reason}
    end
  end
end
