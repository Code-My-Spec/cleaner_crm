defmodule CleanerCrmWeb.ReviewLive.Index do
  @moduledoc """
  The office's review inbox (owner/admin only): every collected review
  and private complaint, most recent first, with each row marked
  public or private so a complaint routed away from publication still
  reaches the owner.

  Route: `/app/reviews`.

  ## Dependencies

  - `CleanerCrm.Reviews`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Reviews

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Reviews
        <:subtitle>Client reviews and private complaints</:subtitle>
      </.header>

      <p :if={@reviews == []} class="text-center py-12 text-base-content/70">
        No reviews yet.
      </p>

      <ul :if={@reviews != []} data-test="reviews-list" class="list">
        <li :for={review <- @reviews} data-test={"review-row-#{review.id}"} class="list-row">
          <div class="list-col-grow">
            <p>
              <span class="font-medium">{client_name(review)}</span>
              <span
                data-test={"review-#{review.id}-visibility"}
                class={["badge badge-sm ml-2", visibility_class(review.status)]}
              >
                {visibility_label(review.status)}
              </span>
            </p>
            <p :if={review.rating} data-test={"review-#{review.id}-rating"}>
              {review.rating} / 5
            </p>
            <p :if={review.text}>{review.text}</p>
          </div>
        </li>
      </ul>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :reviews, Reviews.list_reviews(socket.assigns.current_scope))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Reviews")}
  end

  defp client_name(%{client: %{name: name}}), do: name
  defp client_name(_review), do: "—"

  defp visibility_label(:published), do: "Public"
  defp visibility_label(:private), do: "Private"
  defp visibility_label(:review_requested), do: "Pending"

  defp visibility_class(:published), do: "badge-success"
  defp visibility_class(:private), do: "badge-warning"
  defp visibility_class(:review_requested), do: "badge-ghost"
end
