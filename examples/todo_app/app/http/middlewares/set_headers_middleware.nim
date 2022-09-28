from strutils import join
import asyncdispatch
import ../../../../../src/basolato/middleware


proc setCorsHeadersMiddleware*(c:Context, p:Params):Future[Response] {.async.} =
  let allowedMethods = [
    "OPTIONS",
    "GET",
    "POST",
    "PUT",
    "DELETE"
  ]

  let allowedHeaders = [
    "content-type",
  ]

  let headers = {
    "Cache-Control": @["no-cache"],
    "Access-Control-Allow-Credentials": @[$true],
    "Access-Control-Allow-Origin": @["http://localhost:3000"],
    "Access-Control-Allow-Methods": @allowedMethods,
    "Access-Control-Allow-Headers": @allowedHeaders,
    "Access-Control-Expose-Headers": @allowedHeaders,
  }.newHttpHeaders(true)
  return next(status=Http204, headers=headers)

proc setSecureHeadersMiddlware*(c:Context, p:Params):Future[Response] {.async.} =
  let headers = {
    "Strict-Transport-Security": @["max-age=63072000", "includeSubdomains"],
    "X-Frame-Options": @["SAMEORIGIN"],
    "X-XSS-Protection": @["1", "mode=block"],
    "X-Content-Type-Options": @["nosniff"],
    "Referrer-Policy": @["no-referrer", "strict-origin-when-cross-origin"],
    "Cache-Control": @["no-cache", "no-store", "must-revalidate"],
    "Pragma": @["no-cache"],
  }.newHttpHeaders(true)
  return next(status=Http204, headers=headers)
