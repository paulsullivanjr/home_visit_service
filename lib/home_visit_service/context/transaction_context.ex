defmodule HomeVisitService.Context.TransactionContext do
  import Ecto.Query

  alias Ecto.Multi
  alias HomeVisitService.Repo
  alias HomeVisitService.Schema.Transaction
  alias HomeVisitService.Schema.Visit

  def record_transactions(visit) do
    credit_minutes = calculate_credit_minutes(visit.minutes)

    Multi.new()
    |> Multi.insert(
      :debit,
      Transaction.debit_changeset(%Transaction{}, %{
        visit_id: visit.id,
        user_id: visit.member_id,
        minutes: visit.minutes
      })
    )
    |> Multi.insert(
      :credit,
      Transaction.credit_changeset(%Transaction{}, %{
        visit_id: visit.id,
        user_id: visit.pal_id,
        minutes: credit_minutes
      })
    )
    |> Repo.transaction()
  end

  def create_credit_add_transaction(attrs) do
    Transaction.credit_add_changeset(%Transaction{}, attrs)
    |> Repo.insert()
  end

  defp calculate_credit_minutes(minutes) do
    floor(minutes * 0.85)
  end

  def get_user_transactions(user_id, transaction_type \\ nil) do
    query = from(t in Transaction, where: t.user_id == ^user_id)

    query =
      case transaction_type do
        nil -> query
        _type -> from(t in query, where: t.type == ^transaction_type)
      end

    Repo.all(query)
  end

  def get_visit_transactions(visit_id) do
    Repo.all(from(t in Transaction, where: t.visit_id == ^visit_id))
  end

  def net_available_minutes(user_id) do
    get_available_minutes(user_id) - get_pending_minutes(user_id)
  end

  def get_available_minutes(user_id) do
    query =
      from(t in Transaction,
        where: t.user_id == ^user_id,
        select: {
          sum(fragment("CASE WHEN ? = 'credit' THEN ? ELSE 0 END", t.type, t.minutes)),
          sum(fragment("CASE WHEN ? = 'credit_add' THEN ? ELSE 0 END", t.type, t.minutes)),
          sum(fragment("CASE WHEN ? = 'debit' THEN ? ELSE 0 END", t.type, t.minutes))
        }
      )

    Repo.one(query)
    |> case do
      {nil, nil, nil} -> 0
      {credit, credit_add, debit} -> (credit || 0) + (credit_add || 0) - (abs(debit) || 0)
    end
  end

  def get_pending_minutes(user_id) do
    Repo.one(
      from(v in Visit,
        where: v.member_id == ^user_id and v.status == :requested,
        select: sum(v.minutes)
      )
    ) || 0
  end
end
