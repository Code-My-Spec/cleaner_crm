defmodule CleanerCrm.Reviews.ReviewTest do
  use CleanerCrmTest.DataCase, async: true

  alias CleanerCrm.Reviews.Review

  @valid_attrs %{
    job_id: Ecto.UUID.generate(),
    client_id: Ecto.UUID.generate(),
    token: "review_token_123",
    status: :review_requested,
    review_request_sent_at: DateTime.utc_now()
  }

  describe "changeset/2" do
    test "valid with just the request-side fields, no rating yet" do
      changeset = Review.changeset(%Review{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires job_id, client_id, and token" do
      changeset = Review.changeset(%Review{}, %{})
      refute changeset.valid?

      assert %{
               job_id: ["can't be blank"],
               client_id: ["can't be blank"],
               token: ["can't be blank"]
             } =
               errors_on(changeset)
    end

    test "rejects a rating outside 1..5" do
      changeset = Review.changeset(%Review{}, Map.put(@valid_attrs, :rating, 6))
      refute changeset.valid?
      assert %{rating: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "submission_changeset/2" do
    test "valid with a rating, text, status, and submitted_at" do
      changeset =
        Review.submission_changeset(%Review{}, %{
          rating: 5,
          text: "Great job!",
          status: :published,
          submitted_at: DateTime.utc_now()
        })

      assert changeset.valid?
    end

    test "requires rating and submitted_at" do
      changeset = Review.submission_changeset(%Review{}, %{})
      refute changeset.valid?

      assert %{rating: ["can't be blank"], submitted_at: ["can't be blank"]} =
               errors_on(changeset)
    end
  end
end
