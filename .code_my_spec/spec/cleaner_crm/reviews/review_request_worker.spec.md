# CleanerCrm.Reviews.ReviewRequestWorker

Oban worker: on job completion sends the thank-you email immediately and schedules the review request ~24h later; skips when a review or private complaint already exists.

## Type

module
