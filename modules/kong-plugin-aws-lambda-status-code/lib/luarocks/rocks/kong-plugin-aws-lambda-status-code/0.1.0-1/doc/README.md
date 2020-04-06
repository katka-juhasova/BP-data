# AWS Lambda status code plugin

This plugin is a fork of [Kong's builtin `aws-lambda` plugin](https://getkong.org/plugins/aws-lambda/).

## Background

AWS Lambda [returns a status code of `200`](https://docs.aws.amazon.com/lambda/latest/dg/API_Invoke.html#API_Invoke_ResponseSyntax) when it executed successfully.

In case you're building a REST API with Lambda, AWS API Gateway provides some logic which can do some response mapping for you.
Kong's current offering is too limited to do so, in particular when it comes to changing the response's status.

It's becoming somehow common practice to get Lambda to return responses in this format:

```json
{
  "statusCode": 200,
  "resource": {
    "foo": "bar"
  }
}
```
So say you're asking Lambda to search for some records in a database. If it doesn't find it, you would want to have `statusCode` to be set to `404`.
Lambda executed properly so it will give you a `200`.

This plugin then does the mapping between that body element and the actual status code returned to the client, and sends just the resource as body.

example:

You're patching something, lambda would return

```json
{
  "statusCode": 202,
  "resource": {
    "foo": "bar"
  }
}
```
After kong processes it, the client finally gets:
Status: `202`
```json
{
  "foo": "bar"
}
```
And that's what the LUA snippet which will allow us to do so looks like:

```lua
local params = cjson.null
local content_type = headers["Content-Type"]
if content_type:find("application/json", nil, true) then
  params, err = cjson.decode(body)
  local statusCode = params.statusCode
  local resource   = params.resource
  if statusCode ~= nil then
    ngx.header['X-lambda-original-status'] = res.status
    ngx.status = statusCode
  end
  if resource ~= nil then
    -- As we're changing the body size, we can't set this header.
    headers['Content-Length'] = nil
    body = cjson.encode(resource)
  end
end
```
