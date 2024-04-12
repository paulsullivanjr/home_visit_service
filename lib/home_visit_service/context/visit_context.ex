defmodule HomeVisitService.Context.VisitContext do
  import Ecto.Query

  alias HomeVisitService.Repo
  alias HomeVisitService.Schema.Visit

  def create_visit_request(attrs \\ %{}) do
    %Visit{}
    |> Visit.request_visit_changeset(attrs)
    |> Repo.insert()
  end

  def accept_visit_request(%Visit{member_id: member_id} = visit, pal_id)
      when member_id != pal_id do
    visit
    |> Visit.changeset(%{pal_id: pal_id, status: :accepted})
    |> Repo.update()
  end

  def accept_visit_request(%Visit{member_id: member_id}, pal_id) when member_id == pal_id,
    do: {:error, :pal_cannot_be_member}

  def complete_visit(%Visit{status: :accepted} = visit) do
    visit
    |> Visit.changeset(%{status: :completed})
    |> Repo.update()
  end

  def complete_visit(_) do
    {:error, :only_accepted_visits_can_be_completed}
  end

  def get_visit(id) do
    case Repo.get(Visit, id) do
      nil -> {:error, :not_found}
      visit -> {:ok, visit}
    end
  end

  def get_visits_by_user(user_id) do
    Repo.all(from(v in Visit, where: v.member_id == ^user_id or v.pal_id == ^user_id))
  end

  def get_visits_by_status(status) do
    Repo.all(from(v in Visit, where: v.status == ^status))
  end

  def get_visits_for_pal(pal_id, status) do
    Repo.all(from(v in Visit, where: v.member_id != ^pal_id and v.status == ^status))
  end

  def get_visits_for_member(member_id, status) do
    Repo.all(from(v in Visit, where: v.pal_id != ^member_id and v.status == ^status))
  end
end
