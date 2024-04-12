defmodule HomeVisitServiceTest do
  use ExUnit.Case

  alias HomeVisitService

  @valid_date ~U[2024-04-10 18:27:05.916279Z]

  describe "request_visit/4" do
    test "creates a visit request successfully" do
      {:ok, member} = create_user()

      assert {:ok, visit} =
               HomeVisitService.request_visit(
                 member.id,
                 @valid_date,
                 60,
                 "Task 1"
               )

      assert visit.status == :requested
      assert {:ok, _visit} = HomeVisitService.get_visit(visit.id)
    end
  end

  describe "get visits" do
    test "get_visit/1" do
      {:error, :not_found} = HomeVisitService.get_visit(0)
    end

    test "get_visits_by_user/1" do
      {:ok, member} = create_user()
      assert [] = HomeVisitService.get_visits_by_user(member.id)
    end
  end

  describe "accept_visit/2" do
    test "succesfully accepts a visit request" do
      {:ok, member} = create_user()
      {:ok, pal} = create_user()

      assert {:ok, visit} =
               HomeVisitService.request_visit(
                 member.id,
                 @valid_date,
                 60,
                 "Task 1"
               )

      assert {:ok, accepted_visit} = HomeVisitService.accept_visit(visit.id, pal.id)
      assert accepted_visit.status == :accepted
    end

    test "fails to accept a visit when member and apl are the same" do
      {:ok, member} = create_user()

      assert {:ok, visit} =
               HomeVisitService.request_visit(
                 member.id,
                 @valid_date,
                 60,
                 "Task 1"
               )

      assert {:error, :pal_cannot_be_member} =
               HomeVisitService.accept_visit(visit.id, member.id)
    end
  end

  describe "complete_visit/2" do
    test "completes a visit and records transaction" do
      {:ok, member} = create_user()
      {:ok, pal} = create_user()

      assert {:ok, visit_request} =
               HomeVisitService.request_visit(
                 member.id,
                 @valid_date,
                 60,
                 "Task 1"
               )

      assert {:ok, visit} = HomeVisitService.accept_visit(visit_request.id, pal.id)
      assert {:ok, completed_visit} = HomeVisitService.complete_visit(visit, member.id)
      assert completed_visit.status == :completed
    end

    test "returns :error when user tries to complete unaccepted visit" do
      {:ok, member} = create_user()
      {:ok, pal} = create_user()

      assert {:ok, visit} =
               HomeVisitService.request_visit(
                 member.id,
                 ~U[2024-04-10 18:27:05.916279Z],
                 60,
                 "Task 1"
               )

      assert {:error, :only_accepted_visits_can_be_completed} =
               HomeVisitService.complete_visit(visit, pal.id)
    end
  end

  describe "avaiable_visits/0" do
    test "returns available visits" do
      {:ok, member} = create_user()
      {:ok, pal} = create_user()

      {:ok, _visit} =
        HomeVisitService.request_visit(
          member.id,
          ~U[2024-04-10 18:27:05.916279Z],
          60,
          "Task 1"
        )

      visits = HomeVisitService.available_visits_for_pal(pal.id)

      assert length(visits) > 0
    end
  end

  describe "get_user_transactions/1" do
    test "returns transactions for user" do
      {:ok, member} = create_user()
      {:ok, pal} = create_user()

      assert {:ok, visit_request} =
               HomeVisitService.request_visit(
                 member.id,
                 @valid_date,
                 60,
                 "Task 1"
               )

      assert {:ok, visit} = HomeVisitService.accept_visit(visit_request.id, pal.id)
      assert {:ok, _completed_visit} = HomeVisitService.complete_visit(visit, member.id)
      member_transactions = HomeVisitService.get_user_transactions(member.id)
      pal_transactions = HomeVisitService.get_user_transactions(pal.id)

      assert length(member_transactions) > 1
      assert length(pal_transactions) > 1
    end

    test "get_user_transactions/1 type :credit" do
      transactions = HomeVisitService.get_user_transactions(1, :credit)

      assert length(transactions) < 1
    end
  end

  describe "get_available_minutes_for_user/1" do
    test "returns available minutes for new user" do
      {:ok, member} = create_user()
      {:ok, pal} = create_user()
      available_minutes = HomeVisitService.get_available_minutes_for_user(member.id)
      assert available_minutes == 180

      available_minutes = HomeVisitService.get_available_minutes_for_user(pal.id)
      assert available_minutes == 180
    end

    test "returns available minutes for user with transactions" do
      {:ok, member} = create_user()
      {:ok, pal} = create_user()

      assert {:ok, visit_request} =
               HomeVisitService.request_visit(
                 member.id,
                 @valid_date,
                 60,
                 "Task 1"
               )

      assert {:ok, visit} = HomeVisitService.accept_visit(visit_request.id, pal.id)
      assert {:ok, _completed_visit} = HomeVisitService.complete_visit(visit, member.id)

      available_minutes = HomeVisitService.get_available_minutes_for_user(member.id)
      assert available_minutes == 120

      available_minutes = HomeVisitService.get_available_minutes_for_user(pal.id)
      assert available_minutes == 231
    end
  end

  describe "list_users/0" do
    test "returns a list of users" do
      users = HomeVisitService.list_users()

      assert length(users) > 0
    end
  end

  describe "get_user/1" do
    test "succesfully returns user" do
      {:ok, user} = HomeVisitService.get_user(1)
      assert user
    end
  end

  describe "update_user/2" do
    test "succesfully updates user" do
      {:ok, user} = HomeVisitService.get_user(1)

      assert {:ok, _} =
               HomeVisitService.update_user(user.id, %{first_name: "Jane"})
    end
  end

  defp create_user() do
    date_time = System.system_time(:millisecond)
    first_name = Faker.Person.first_name()
    email = "#{first_name}+#{date_time}@foo.com"

    HomeVisitService.create_user(
      first_name,
      Faker.Person.last_name(),
      email
    )
  end
end
