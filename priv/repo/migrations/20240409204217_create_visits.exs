defmodule HomeVisitService.Repo.Migrations.CreateVisits do
  use Ecto.Migration

  def change do
    create table(:visits) do
      add :visit_date, :naive_datetime
      add :minutes, :integer
      add :task, :string
      add :status, :string

      add :member_id, references(:users, on_delete: :nothing), null: false

      add :pal_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:visits, [:member_id])
    create index(:visits, [:pal_id])
  end
end
