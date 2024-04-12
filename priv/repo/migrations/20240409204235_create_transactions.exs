defmodule HomeVisitService.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :type, :string, null: false
      add :visit_id, references(:visits, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :minutes, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:transactions, [:visit_id])
    create index(:transactions, [:user_id])
  end
end
