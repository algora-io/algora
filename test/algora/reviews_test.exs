defmodule Algora.ReviewsTest do
  use Algora.DataCase
  use Oban.Testing, repo: Algora.Repo

  alias Algora.Reviews

  describe "reviews" do
    test "create" do
      reviewer = insert(:user)
      reviewee = insert(:user)
      org = insert(:organization)
      contract = insert(:contract, client: reviewer, contractor: reviewee)

      {:ok, review} =
        Reviews.create_review(%{
          rating: 5,
          content: "NICE!",
          visibility: :public,
          contract_id: contract.id,
          organization_id: org.id,
          reviewee_id: reviewee.id,
          reviewer_id: reviewer.id
        })

      assert [reviewee_id: reviewee.id]
             |> Reviews.list_reviews()
             |> Enum.map(& &1.id) == [review.id]
    end
  end
end
