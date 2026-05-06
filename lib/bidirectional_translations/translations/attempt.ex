defmodule BidirectionalTranslations.Translations.Attempt do
  use Ecto.Schema
  import Ecto.Changeset

  alias BidirectionalTranslations.Translations.Session

  schema "attempts" do
    field :body, :string

    belongs_to :session, Session

    timestamps(type: :utc_datetime)
  end

  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [:body, :session_id])
    |> validate_required([:body, :session_id])
    |> foreign_key_constraint(:session_id)
    |> unique_constraint(:session_id)
  end
end
