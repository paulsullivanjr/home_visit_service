defmodule HomeVisitService.Schema.Visit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "visits" do
    field(:status, Ecto.Enum, values: [:requested, :accepted, :completed])
    field(:minutes, :integer)
    field(:visit_date, :naive_datetime)
    field(:task, :string)
    field(:member_id, :id)
    field(:pal_id, :id)

    timestamps(type: :utc_datetime)
  end

  def changeset(visit, attrs) do
    visit
    |> cast(attrs, [:visit_date, :minutes, :task, :member_id, :pal_id, :status])
    |> validate_required([:visit_date, :minutes, :task, :member_id, :pal_id, :status])
  end

  def request_visit_changeset(visit, attrs) do
    visit
    |> cast(attrs, [:visit_date, :minutes, :task, :member_id, :status])
    |> validate_required([:visit_date, :minutes, :task, :member_id, :status])
  end
end
