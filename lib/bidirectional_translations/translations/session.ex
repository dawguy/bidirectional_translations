defmodule BidirectionalTranslations.Translations.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias BidirectionalTranslations.Accounts.User
  alias BidirectionalTranslations.Translations.{Article, Attempt}

  schema "sessions" do
    field :direction, Ecto.Enum, values: [:target_to_english, :english_to_target]
    field :scheduled_date, :date
    field :status, Ecto.Enum, values: [:pending, :completed, :postponed], default: :pending
    field :completed_at, :utc_datetime

    belongs_to :article, Article
    belongs_to :user, User
    has_one :attempt, Attempt

    timestamps(type: :utc_datetime)
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [:direction, :scheduled_date, :status, :completed_at, :article_id, :user_id])
    |> validate_required([:direction, :scheduled_date, :article_id, :user_id])
    |> foreign_key_constraint(:article_id)
    |> foreign_key_constraint(:user_id)
  end
end
