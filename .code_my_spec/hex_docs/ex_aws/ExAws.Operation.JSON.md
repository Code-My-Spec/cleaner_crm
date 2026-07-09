# ExAws.Operation.JSON

Datastructure representing an operation on a JSON based AWS service.

This module is generally not used directly, but rather is constructed by one
of the relevant AWS services.

These include:
- DynamoDB
- Kinesis
- Lambda (Rest style)
- ElasticTranscoder

JSON services are generally pretty simple. You just need to populate the `data`
attribute with whatever request body parameters need converted to JSON, and set
any service specific headers.

The `before_request`