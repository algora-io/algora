defmodule Algora.RepoTest do
  use Algora.DataCase

  alias Algora.Accounts.User
  alias Algora.Repo

  describe "transact/2" do
    test "commits transaction when {:ok, result} is returned" do
      user = insert(:user)
      original_email = user.email

      {:ok, result} =
        Repo.transact(fn _repo ->
          {:ok, updated_user} = user |> Ecto.Changeset.change(%{email: "success@example.com"}) |> Repo.update()
          {:ok, updated_user}
        end)

      assert result.email == "success@example.com"
      assert Repo.get!(User, user.id).email == "success@example.com"
      refute Repo.get!(User, user.id).email == original_email
    end

    test "commits transaction when :ok is returned" do
      user = insert(:user)
      original_email = user.email

      {:ok, result} =
        Repo.transact(fn _repo ->
          {:ok, _updated_user} = user |> Ecto.Changeset.change(%{email: "ok@example.com"}) |> Repo.update()
          :ok
        end)

      assert result == nil
      assert Repo.get!(User, user.id).email == "ok@example.com"
      refute Repo.get!(User, user.id).email == original_email
    end

    test "rolls back transaction when anything else is returned" do
      user = insert(:user)
      original_email = user.email

      # Test plain error atom
      {:error, result} =
        Repo.transact(fn _repo ->
          {:ok, _updated_user} = user |> Ecto.Changeset.change(%{email: "error@example.com"}) |> Repo.update()
          :error
        end)

      assert result == :error
      assert Repo.get!(User, user.id).email == original_email

      # Test error tuple
      {:error, result} =
        Repo.transact(fn _repo ->
          {:ok, _updated_user} = user |> Ecto.Changeset.change(%{email: "error_tuple@example.com"}) |> Repo.update()
          {:error, "reason"}
        end)

      assert result == "reason"
      assert Repo.get!(User, user.id).email == original_email

      # Test unexpected return value
      {:error, result} =
        Repo.transact(fn _repo ->
          {:ok, _updated_user} = user |> Ecto.Changeset.change(%{email: "unexpected@example.com"}) |> Repo.update()
          "unexpected"
        end)

      assert result == "unexpected"
      assert Repo.get!(User, user.id).email == original_email
    end

    test "rolls back transaction when an error is raised" do
      user = insert(:user)
      original_email = user.email

      assert_raise RuntimeError, "boom", fn ->
        Repo.transact(fn _repo ->
          {:ok, _updated_user} = user |> Ecto.Changeset.change(%{email: "raised@example.com"}) |> Repo.update()
          raise "boom"
        end)
      end

      assert Repo.get!(User, user.id).email == original_email
    end

    test "commits nested transactions when all succeed" do
      user = insert(:user)
      original_email = user.email

      {:ok, result} =
        Repo.transact(fn _repo ->
          {:ok, user1} = user |> Ecto.Changeset.change(%{email: "outer@example.com"}) |> Repo.update()

          {:ok, user2} =
            Repo.transact(fn _repo ->
              user1 |> Ecto.Changeset.change(%{email: "inner@example.com"}) |> Repo.update()
            end)

          {:ok, user2}
        end)

      assert result.email == "inner@example.com"
      assert Repo.get!(User, user.id).email == "inner@example.com"
      refute Repo.get!(User, user.id).email == original_email
    end

    test "rolls back nested transactions when inner transaction fails" do
      user = insert(:user)
      original_email = user.email

      {:error, result} =
        Repo.transact(fn _repo ->
          {:ok, user1} = user |> Ecto.Changeset.change(%{email: "outer@example.com"}) |> Repo.update()

          Repo.transact(fn _repo ->
            {:ok, _user2} = user1 |> Ecto.Changeset.change(%{email: "inner@example.com"}) |> Repo.update()
            {:error, :inner_failed}
          end)

          {:ok, user1}
        end)

      assert result == :rollback
      assert Repo.get!(User, user.id).email == original_email
    end

    test "rolls back nested transactions when outer transaction fails" do
      user = insert(:user)
      original_email = user.email

      {:error, result} =
        Repo.transact(fn _repo ->
          {:ok, user1} = user |> Ecto.Changeset.change(%{email: "outer@example.com"}) |> Repo.update()

          {:ok, _user2} =
            Repo.transact(fn _repo ->
              user1 |> Ecto.Changeset.change(%{email: "inner@example.com"}) |> Repo.update()
            end)

          {:error, :outer_failed}
        end)

      assert result == :outer_failed
      assert Repo.get!(User, user.id).email == original_email
    end
  end
end
