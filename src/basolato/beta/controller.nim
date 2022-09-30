import std/asyncdispatch; export asyncdispatch
import std/asyncfile; export asyncdispatch
import std/os
import std/tables; export tables
import core/base; export base
import core/request; export request
import core/response; export response
import core/route; export route
import core/header; export header
import core/security/cookie; export cookie
import core/security/session; export session
import core/security/context; export context


type Controller* = proc(c:Context, params:Params):Future[Response] {.async.}

proc asyncHtml*(path:string):Future[string] {.async.} =
  ## Open html file asynchronous.
  ## arg path is relative path from app/http/views
  ## .. code-block:: nim
  ##   let indexHtml = await asyncHtml("pages/index.html")
  ##   return render(indexHtml)
  let path = getCurrentDir() / "app/http/views" / path
  let f = openAsync(path, fmRead)
  defer: f.close()
  let data = await f.readAll()
  return $data

proc html*(path:string):string =
  ## Open html file.
  ## arg path is relative path from app/http/views
  ## .. code-block:: nim
  ##   let indexHtml = html("pages/index.html")
  ##   return render(indexHtml)
  let path = getCurrentDir() / "app/http/views" / path
  let f = open(path, fmRead)
  defer: f.close()
  let data = f.readAll()
  return $data
