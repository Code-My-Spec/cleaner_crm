defmodule CleanerCrmWeb.ReviewLive.Public do
  @moduledoc """
  The public, token-link review page a client reaches from their
  review-request email: a 1-5 star rating plus optional text,
  one-tap submission. A rating of 4-5 publishes the review; 3 or
  below routes it to a private complaint sent to the owner instead.

  Route: `/reviews/:token`. No login — reached from a mailed link, so
  it lives in the `:current_user` style `live_session` (mounts
  `current_scope` for the root layout without requiring one).

  ## Dependencies

  - `CleanerCrm.Reviews`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Reviews
  alias CleanerCrm.Reviews.Review

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-md mx-auto px-2">
        <div :if={is_nil(@review)} data-test="review-invalid-notice" class="alert alert-error">
          This review link is invalid.
        </div>

        <div :if={@review}>
          <.header>How was your cleaning?</.header>

          <div :if={!@submitted}>
            <div data-test="review-rating" class="flex gap-2 my-4">
              <button
                :for={n <- 1..5}
                type="button"
                data-test={"review-rating-#{n}"}
                phx-click="set_rating"
                phx-value-rating={n}
                class={["btn btn-circle", @rating == n && "btn-primary"]}
              >
                {n}
              </button>
            </div>

            <form id="review-form" data-test="review-form" phx-submit="submit_review">
              <textarea
                name="review[text]"
                placeholder="Tell us about your visit (optional)"
                class="textarea textarea-bordered w-full"
              ></textarea>

              <.button type="submit" data-test="submit-review-button" class="mt-2">
                Submit Review
              </.button>
            </form>
          </div>

          <div
            :if={@submitted && @review.status == :published}
            data-test="review-published-notice"
            class="alert alert-success"
          >
            Thank you! Your review is on its way to being published.
          </div>

          <div
            :if={@submitted && @review.status == :private}
            data-test="review-private-notice"
            class="alert alert-warning"
          >
            Thanks for letting us know — we've sent your note directly to the owner.
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Reviews.get_review_by_token(token) do
      nil ->
        {:ok, assign(socket, review: nil, rating: nil, submitted: false)}

      %Review{status: :review_requested} = review ->
        {:ok, assign(socket, review: review, rating: nil, submitted: false)}

      %Review{} = review ->
        {:ok, assign(socket, review: review, rating: review.rating, submitted: true)}
    end
  end

  @impl true
  def handle_event("set_rating", %{"rating" => rating}, socket) do
    {:noreply, assign(socket, :rating, String.to_integer(rating))}
  end

  def handle_event("submit_review", %{"review" => params}, socket) do
    do_submit(socket, socket.assigns.submitted, socket.assigns.rating, params)
  end

  defp do_submit(socket, true, _rating, _params), do: {:noreply, socket}

  defp do_submit(socket, false, nil, _params) do
    {:noreply, put_flash(socket, :error, "Please select a rating first.")}
  end

  defp do_submit(socket, false, rating, params) do
    case Reviews.submit_review(socket.assigns.review, rating, Map.get(params, "text")) do
      {:ok, updated} -> {:noreply, assign(socket, review: updated, submitted: true)}
      {:error, _changeset} -> {:noreply, put_flash(socket, :error, "Something went wrong.")}
    end
  end
end
