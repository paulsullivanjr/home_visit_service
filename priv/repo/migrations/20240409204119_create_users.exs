defmodule HomeVisitService.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :first_name, :string
      add :last_name, :string
      add :email, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email], name: :users_email_index)
  end
end
