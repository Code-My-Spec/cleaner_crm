# ExAws

Module for making and processing AWS requests.

## request/2

Perform an AWS request.

First build an operation from one of the services, and then pass it to this
function to perform it.

If you want to build an operation manually, see: `ExAws.Operation`

This function takes an optional second parameter of configuration overrides.
This is useful if you want to have certain configuration changed on a per
request basis.

Also you can configure telemetry metrics with:

  * `:telemetry_event` - The telemetry event name to dispatch the event under.
    Defaults to `[:ex_aws, :request]`.
  * `:telemetry_options` - Extra options to attach to telemetry event name.

## Examples

If you have one of the service modules installed, you can just use those service
modules like this:

    ExAws.S3.list_buckets |> ExAws.request

    ExAws.S3.list_buckets |> ExAws.request(region: "eu-west-1")

    ExAws.Dynamo.get_object("users", "foo@bar.com") |> ExAws.request

Alternatively you can create operation structs manually for services
that aren't supported:

    op = %ExAws.Operation.JSON{
      http_method: :post,
      service: :dynamodb,
      headers: [
        {"x-amz-target", "DynamoDB_20120810.ListTables"},
        {"content-type", "application/x-amz-json-1.0"}
      ],
    }

    ExAws.request(op)

## Telemetry events

The following events are published:

* `[:ex_aws, :request, :start]` - dispatched on start every request sent to the AWS.
* `[:ex_aws, :request, :stop]` - dispatched on every response from AWS.
* `[:ex_aws, :request, :exception]` - dispatched after exceptions on request sent to AWS.

With `:metadata` map including the following fields:

  * `:result` - the request result: `:ok` or `:error`
  * `:attempt` - the attempt number
  * `:service` - the AWS service
  * `:options` - extra options given to the repo operation under
    `:telemetry_options`

## request!/2

Perform an AWS request, raise if it fails.

Same as `request/1,2` except it will either return the successful response from
AWS or raise an exception.

## stream!/2

Return a stream for the AWS resource.

## Examples

    ExAws.S3.list_objects("my-bucket") |> ExAws.stream!