defmodule Algora.JobsTest do
  use Algora.DataCase

  import Algora.Factory

  alias Algora.Jobs
  alias Algora.Jobs.JobApplication
  alias Algora.Repo

  describe "withdraw_application/2" do
    test "deletes the current user's application" do
      user = insert!(:user)
      job = insert!(:job_posting, user: insert!(:user))

      assert {:ok, application} = Jobs.create_application(job.id, user)
      assert MapSet.member?(Jobs.list_user_applications(user), job.id)

      assert {:ok, deleted_application} = Jobs.withdraw_application(job.id, user)
      assert deleted_application.id == application.id
      refute MapSet.member?(Jobs.list_user_applications(user), job.id)
      refute Repo.get(JobApplication, application.id)
    end

    test "does not delete another user's application" do
      owner = insert!(:user)
      other_user = insert!(:user)
      job = insert!(:job_posting, user: insert!(:user))

      assert {:ok, application} = Jobs.create_application(job.id, owner)
      assert {:error, :not_found} = Jobs.withdraw_application(job.id, other_user)
      assert Repo.get(JobApplication, application.id)
    end
  end
end
