import
  asynchttpserver, asyncdispatch, asyncfile, json, tables, strformat, macros,
  strutils, re, os, mimetypes
import request, response, header, logger, error_page, resources/ddPage
export request, header


type Params* = ref object
  urlParams*:JsonNode
  queryParams*:QueryParams
  requestParams*:RequestParams

type Route* = ref object
  httpMethod*:HttpMethod
  path*:string
  action*:proc(r:Request, p:Params):Future[Response]

type MiddlewareRoute* = ref object
  path*:string
  action*:proc(r:Request, p:Params)


proc params*(request:Request, route:Route):Params =
  let url = request.path
  let path = route.path
  return Params(
    urlParams: getUrlParams(url, path),
    queryParams: getQueryParams(request),
    requestParams: getRequestParams(request)
  )

proc params*(request:Request, middleware:MiddlewareRoute):Params =
  let url = request.path
  let path = middleware.path
  return Params(
    urlParams: getUrlParams(url, path),
    queryParams: getQueryParams(request),
    requestParams: getRequestParams(request)
  )

type Routes* = ref object
  values: seq[Route]
  middlewares: seq[MiddlewareRoute]

proc newRoutes*():Routes =
  return Routes()

proc newRoute(httpMethod:HttpMethod, path:string, action:proc(r:Request, p:Params):Future[Response]):Route =
  return Route(
    httpMethod:httpMethod,
    path:path,
    action:action
  )

proc add*(this:var Routes, httpMethod:HttpMethod, path:string, action:proc(r:Request, p:Params):Future[Response]) =
  this.values.add(
    newRoute(httpMethod, path, action)
  )

proc middleware*(this:var Routes, path:string, action:proc(r:Request, p:Params)) =
  this.middlewares.add(
    MiddlewareRoute(
      path: path,
      action: action
    )
  )

proc get*(this:var Routes, path:string, action:proc(r:Request, p:Params):Future[Response]) =
  add(this, HttpGet, path, action)

proc post*(this:var Routes, path:string, action:proc(r:Request, p:Params):Future[Response]) =
  add(this, HttpPost, path, action)

proc put*(this:var Routes, path:string, action:proc(r:Request, p:Params):Future[Response]) =
  add(this, HttpPut, path, action)

proc patch*(this:var Routes, path:string, action:proc(r:Request, p:Params):Future[Response]) =
  add(this, HttpPatch, path, action)

proc delete*(this:var Routes, path:string, action:proc(r:Request, p:Params):Future[Response]) =
  add(this, HttpDelete, path, action)

proc head*(this:var Routes, path:string, action:proc(r:Request, p:Params):Future[Response]) =
  add(this, HttpHead, path, action)

proc options*(this:var Routes, path:string, action:proc(r:Request, p:Params):Future[Response]) =
  add(this, HttpOptions, path, action)

proc trace*(this:var Routes, path:string, action:proc(r:Request, p:Params):Future[Response]) =
  add(this, HttpTrace, path, action)

proc connect*(this:var Routes, path:string, action:proc(r:Request, p:Params):Future[Response]) =
  add(this, HttpConnect, path, action)

macro groups*(head, body:untyped):untyped =
  var newNode = ""
  for row in body:
    let rowNode = fmt"""
{row[0].repr}("{head}{row[1]}", {row[2].repr})
"""
    newNode.add(rowNode)
  return parseStmt(newNode)


const errorStatusArray* = [505, 504, 503, 502, 501, 500, 451, 431, 429, 428, 426,
  422, 421, 418, 417, 416, 415, 414, 413, 412, 411, 410, 409, 408, 407, 406,
  405, 404, 403, 401, 400, 307, 305, 304, 303, 302, 301, 300]

macro createHttpCodeError():untyped =
  var strBody = ""
  for num in errorStatusArray:
    strBody.add(fmt"""
of "Error{num.repr}":
  return Http{num.repr}
""")
  return parseStmt(fmt"""
case $exception.name
{strBody}
else:
  return Http400
""")

proc checkHttpCode(exception:ref Exception):HttpCode =
  ## Generated by macro createHttpCodeError.
  ## List is httpCodeArray
  ## .. code-block:: nim
  ##   case $exception.name
  ##   of Error505:
  ##     return Http505
  ##   of Error504:
  ##     return Http504
  ##   of Error503:
  ##     return Http503
  ##   .
  ##   .
  createHttpCodeError


template serve*(routes:var Routes, port=5000) =
  var server = newAsyncHttpServer()
  proc cb(req: Request) {.async, gcsafe.} =
    var headers = newDefaultHeaders()
    headers.set("Content-Type", "text/html; charset=UTF-8")
    var response = Response(status:Http404, body:errorPage(Http404, ""), headers:headers)

    headers = newDefaultHeaders()
    # static file response
    if req.path.contains("."):
      let filepath = getCurrentDir() & "/public" & req.path
      if existsFile(filepath):
        let file = openAsync(filepath, fmRead)
        let data = await file.readAll()
        let contentType = newMimetypes().getMimetype(req.path.split(".")[^1])
        headers.set("Content-Type", contentType)
        response = Response(status:Http200, body:data, headers:headers)
    else:
      block middlewareAndApp:
        # middleware:
        for route in routes.middlewares:
          try:
            if find(req.path, re route.path) >= 0:
              let params = req.params(route)
              route.action(req, params)
          except Exception:
            headers.set("Content-Type", "text/html; charset=UTF-8")
            let exception = getCurrentException()
            if exception.name == "ErrorRedirect".cstring:
              headers.set("Location", exception.msg)
              response = Response(status:Http302, body:"", headers:headers)
            else:
              let status = checkHttpCode(exception)
              response = Response(status:status, body:errorPage(status, exception.msg), headers:headers)
              echoErrorMsg($response.status & "  " & req.hostname & "  " & $req.httpMethod & "  " & req.path)
              echoErrorMsg(exception.msg)
            break middlewareAndApp
        # web app routes
        for route in routes.values:
          try:
            if route.httpMethod == req.httpMethod() and isMatchUrl(req.path, route.path):
              let params = req.params(route)
              response = await route.action(req, params)
              logger($response.status & "  " & req.hostname & "  " & $req.httpMethod & "  " & req.path)
              break
          except Exception:
            headers.set("Content-Type", "text/html; charset=UTF-8")
            let exception = getCurrentException()
            if exception.name == "DD".cstring:
              var msg = exception.msg
              msg = msg.replace(re"Async traceback:[.\s\S]*")
              response = Response(status:Http200, body:ddPage(msg), headers:headers)
            elif exception.name == "ErrorRedirect".cstring:
              headers.set("Location", exception.msg)
              response = Response(status:Http302, body:"", headers:headers)
            else:
              let status = checkHttpCode(exception)
              response = Response(status:status, body:errorPage(status, exception.msg), headers:headers)
              echoErrorMsg($response.status & "  " & req.hostname & "  " & $req.httpMethod & "  " & req.path)
              echoErrorMsg(exception.msg)
              break
    await req.respond(response.status, response.body, response.headers.toResponse())
  waitFor server.serve(Port(port), cb)
