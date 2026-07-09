# Req.Utils



## aws_sigv4_headers/1

Create AWS Signature v4.

https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html

## aws_sigv4_url/1

Create AWS Signature v4 URL.

https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html

## format_http_date/1

Formats a datetime as "HTTP Date".

## Examples

    iex> Req.Utils.format_http_date(~U[2024-01-01 09:00:00Z])
    "Mon, 01 Jan 2024 09:00:00 GMT"

## parse_http_date/1

Parses "HTTP Date" as datetime.

## Examples

    iex> Req.Utils.parse_http_date("Mon, 01 Jan 2024 09:00:00 GMT")
    {:ok, ~U[2024-01-01 09:00:00Z]}

## parse_http_date!/1

Parses "HTTP Date" as datetime or raises an error.

## Examples

    iex> Req.Utils.parse_http_date!("Mon, 01 Jan 2024 09:00:00 GMT")
    ~U[2024-01-01 09:00:00Z]

    iex> Req.Utils.parse_http_date!("Mon")
    ** (ArgumentError) cannot parse "Mon" as HTTP date, reason: :invalid_format

## stream_gzip/1

Returns a stream where each element is gzipped.

## Examples

    iex> gzipped = Req.Utils.stream_gzip(~w[foo bar baz]) |> Enum.to_list()
    iex> :zlib.gunzip(gzipped)
    "foobarbaz"

## collect_with_hash/2

Returns a collectable with hash.

## Examples

    iex> collectable = Req.Utils.collect_with_hash([], :md5)
    iex> Enum.into(Stream.duplicate("foo", 2), collectable)
    {~w[foo foo], :erlang.md5("foofoo")}

## encode_form_multipart/2

Encodes fields into "multipart/form-data" format.

## load_netrc/1

Loads .netrc file.

## Examples

    iex> {:ok, pid} = StringIO.open("""
    ...> machine localhost
    ...> login foo
    ...> password bar
    ...> """)
    iex> Req.Utils.load_netrc(pid)
    %{"localhost" => {"foo", "bar"}}

## parse_http_digest/1

Parses HTTP Digest authentication header (RFC 7616).

## Examples

    iex> Req.Utils.parse_http_digest(~s(Digest realm="example", nonce="abc123", qop="auth"))
    %{"realm" => "example", "nonce" => "abc123", "qop" => "auth"}

## http_digest_auth/6

Generates HTTP Digest authentication header (RFC 7616).

Takes a challenge header from the server's `WWW-Authenticate` response and generates
the corresponding `Authorization` header value for digest authentication.

Returns `{:ok, header_value}` on success or `{:error, reason}` on failure.

## Options

  * `:count` - The nonce count (default: 1). Used for tracking request count with same nonce.

## Examples

    challenge = ~s(Digest realm="example", nonce="abc123", qop="auth")
    {:ok, value} = Req.Utils.http_digest_auth(challenge, "user", "pass", :get, "/path")
    #=> {:ok, "Digest response=..."}