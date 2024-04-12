defmodule HomeVisitService.Schema.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field(:minutes, :integer)
    field(:type, Ecto.Enum, values: [:credit, :debit, :credit_add])

    belongs_to(:visit, HomeVisitService.Schema.Visit)
    belongs_to(:user, HomeVisitService.Schema.User)

    timestamps()
  end

  def debit_changeset(transaction, attrs) do
    updated_attrs = Map.merge(attrs, %{minutes: -abs(attrs.minutes), type: :debit})
    changeset(transaction, updated_attrs)
  end

  def credit_changeset(transaction, attrs) do
    updated_attrs = Map.merge(attrs, %{minutes: abs(attrs.minutes), type: :credit})
    changeset(transaction, updated_attrs)
  end

  def credit_add_changeset(transaction, attrs) do
    updated_attrs = Map.merge(attrs, %{minutes: abs(attrs.minutes), type: :credit_add})

    transaction
    |> cast(updated_attrs, [:minutes, :user_id, :type])
    |> validate_required([:minutes, :user_id, :type])
  end

  defp changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:minutes, :visit_id, :user_id, :type])
    |> validate_required([:minutes, :visit_id, :user_id, :type])
  end
end
