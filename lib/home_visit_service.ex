defmodule HomeVisitService do
  @moduledoc """
  Main module for the HomeVisitService application.
  """
  alias HomeVisitService.Context.TransactionContext
  alias HomeVisitService.Context.UserContext
  alias HomeVisitService.Context.VisitContext
  alias HomeVisitService.Schema.Visit

  @doc """
  Creates a new user and adds 180 minutes to their account.

  ## Parameters
    - first_name - The user's first name.
    - last_name - The user's last name.
    - email - The user's email address.

  ## Examples
    iex> HomeVisitService.create_user("John", "Doe", "foo@foo.com")
    {:ok, %User{}}

  """
  def create_user(first_name, last_name, email) do
    case UserContext.create_user(%{first_name: first_name, last_name: last_name, email: email}) do
      {:ok, user} ->
        TransactionContext.create_credit_add_transaction(%{user_id: user.id, minutes: 180})
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Lists all users.
  """
  def list_users() do
    UserContext.list_users()
  end

  @doc """
  Gets a user by ID.
  """
  def get_user(user_id) do
    UserContext.get_user(user_id)
  end

  @doc """
  Updates a user's information.
  """
  def update_user(user_id, attrs) do
    {:ok, user} = UserContext.get_user(user_id)
    UserContext.update_user(user, attrs)
  end

  @doc """
  Requests a visit for a user.

  ## Parameters

    - member_id - The ID of the user requesting the visit.
    - visit_date - The date of the visit.
    - minutes - The number of minutes for the visit.
    - task - The task to be performed during the visit.

  ## Examples

        iex> HomeVisitService.request_visit(1, ~D[2021-01-01], 60, "Cleaning")
        {:ok, %HomeVisitService.Schema.Visit{...}}

  """
  def request_visit(member_id, visit_date, minutes, task) when minutes > 0 do
    case TransactionContext.net_available_minutes(member_id) do
      available_minutes when available_minutes >= minutes ->
        VisitContext.create_visit_request(%{
          member_id: member_id,
          visit_date: visit_date,
          minutes: minutes,
          task: task,
          status: :requested
        })

      _ ->
        {:error, :insufficient_minutes}
    end
  end

  def request_visit(_, _, _, _), do: {:error, :invalid_minutes}

  @doc """
  Get a visit by ID.
  """
  def get_visit(visit_id) do
    VisitContext.get_visit(visit_id)
  end

  @doc """
  Get all visits for a user.
  """
  def get_visits_by_user(user_id) do
    VisitContext.get_visits_by_user(user_id)
  end

  @doc """
  Accept a visit request.

  ## Parameters

    - visit_id - The ID of the visit to accept.
    - pal_id - The ID of the PAL accepting the visit.

  ## Examples

        iex> HomeVisitService.accept_visit(1, 2)
        {:ok, %HomeVisitService.Schema.Visit{...}}
  """
  def accept_visit(visit_id, pal_id) do
    case VisitContext.get_visit(visit_id) do
      {:ok, visit} -> VisitContext.accept_visit_request(visit, pal_id)
      error -> error
    end
  end

  @doc """
  Complete a visit.

  ## Parameters

    - visit - The visit to complete.
    - user_id - The ID of the user completing the visit.

  ## Examples

        iex> HomeVisitService.complete_visit(%HomeVisitService.Schema.Visit{...}, 1)
        {:ok, %HomeVisitService.Schema.Visit{...}}
  """
  def complete_visit(%Visit{} = visit, user_id) do
    visit
    |> validate_requester(user_id)
    |> complete_and_record_transaction()
  end

  def complete_visit(_, _), do: {:error, :invalid_visit}

  @doc """
  Get all transactions for a visit.

  ## Parameters

    - visit_id - The ID of the visit to get transactions for.

  ## Examples

        iex> HomeVisitService.get_visit_transactions(1)
         [%HomeVisitService.Schema.Transaction{...}]
  """
  def get_visit_transactions(visit_id) do
    TransactionContext.get_visit_transactions(visit_id)
  end

  @doc """
  Get all visits for a pal.

  ## Parameters

    - user_id - The ID of the PAL to get visits for.

  ## Examples

          iex> HomeVisitService.available_visits_for_pal(1)
          [%HomeVisitService.Schema.Visit{...}]
  """
  def available_visits_for_pal(user_id) do
    VisitContext.get_visits_for_pal(user_id, :requested)
  end

  @doc """
  Get user transactions

  ## Parameters

  - user_id - The ID of the user to get transactions for.
  - type - The type of transactions to get. Can be `nil` for all transactions, or `:debit`, `:credit_add` or `:credit`.

  ## Examples

    iex> HomeVisitService.get_user_transactions(1)
    {:ok, [%HomeVisitService.Schema.Transaction{...}]}
  """
  def get_user_transactions(user_id, type \\ nil) do
    TransactionContext.get_user_transactions(user_id, type)
  end

  @doc """
  Get available minutes for a user.
  """
  def get_available_minutes_for_user(user_id) do
    TransactionContext.get_available_minutes(user_id)
  end

  defp validate_requester(%{member_id: member_id} = visit, user_id) when member_id == user_id,
    do: visit

  defp validate_requester(_visit, _user_id), do: {:error, :unauthorized}

  defp complete_and_record_transaction(visit) do
    with {:ok, completed_visit} <- VisitContext.complete_visit(visit),
         {:ok, _transactions} <- TransactionContext.record_transactions(completed_visit) do
      {:ok, completed_visit}
    else
      {:error, error} -> {:error, error}
      error -> error
    end
  end
end
