defmodule BidirectionalTranslations.Mailer.RateLimiter do
  use GenServer

  @daily_limit 200

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{date: Date.utc_today(), count: 0}, name: __MODULE__)
  end

  def check_and_increment do
    GenServer.call(__MODULE__, {:check_and_increment_by, 1})
  end

  def check_and_increment_by(n) do
    GenServer.call(__MODULE__, {:check_and_increment_by, n})
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:check_and_increment_by, n}, _from, state) do
    today = Date.utc_today()
    state = if state.date != today, do: %{date: today, count: 0}, else: state

    if state.count + n > @daily_limit do
      {:reply, {:error, :daily_limit_reached}, state}
    else
      {:reply, :ok, %{state | count: state.count + n}}
    end
  end
end
