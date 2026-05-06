defmodule BidirectionalTranslations.Translations.Article do
  use Ecto.Schema
  import Ecto.Changeset

  alias BidirectionalTranslations.Accounts.User
  alias BidirectionalTranslations.Translations.Session

  schema "articles" do
    field :title, :string
    field :language, :string
    field :english_text, :string
    field :target_text, :string
    field :source_url, :string

    belongs_to :user, User
    has_many :sessions, Session

    timestamps(type: :utc_datetime)
  end

  def changeset(article, attrs) do
    article
    |> cast(attrs, [:title, :language, :english_text, :target_text, :source_url])
    |> validate_required([:title, :language, :english_text, :target_text])
    |> validate_length(:title, max: 255)
    |> validate_inclusion(:language, ~w(de ko fr es ja zh it pt ru))
  end
end
