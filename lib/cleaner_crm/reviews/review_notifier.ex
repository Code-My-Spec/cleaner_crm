defmodule CleanerCrm.Reviews.ReviewNotifier do
  @moduledoc """
  Builds and delivers the two review-related emails via
  `CleanerCrm.Mailer` (Swoosh/Resend): the immediate post-job
  thank-you note, and the review-request link sent roughly a day
  later by `CleanerCrm.Reviews.ReviewRequestWorker`.
  """

  import Swoosh.Email

  alias CleanerCrm.Mailer
  alias CleanerCrm.Clients.Client
  alias CleanerCrm.Scheduling.Job

  def deliver_thank_you(%Client{} = client, %Job{} = job) do
    client.email
    |> thank_you_email(job)
    |> Mailer.deliver()
  end

  def deliver_review_request(%Client{} = client, %Job{} = job, review_url) do
    client.email
    |> review_request_email(job, review_url)
    |> Mailer.deliver()
  end

  defp thank_you_email(to, job) do
    new()
    |> to(to)
    |> from({"CleanerCrm", "contact@example.com"})
    |> subject("Thank you for choosing us! A review request will follow soon")
    |> html_body("""
    <p>Thank you for having us clean on #{job.scheduled_date}. We hope it was a great visit!</p>
    <p>We'll follow up in a day or so to ask for a quick review.</p>
    """)
    |> text_body("""
    Thank you for having us clean on #{job.scheduled_date}. We hope it was a great visit!

    We'll follow up in a day or so to ask for a quick review.
    """)
  end

  defp review_request_email(to, job, review_url) do
    new()
    |> to(to)
    |> from({"CleanerCrm", "contact@example.com"})
    |> subject("How was your cleaning on #{job.scheduled_date}? Leave a review")
    |> html_body("""
    <p>We'd love to hear how your recent cleaning visit went.</p>
    <p><a href="#{review_url}">Leave a review</a></p>
    """)
    |> text_body("""
    We'd love to hear how your recent cleaning visit went.

    Leave a review: #{review_url}
    """)
  end
end
