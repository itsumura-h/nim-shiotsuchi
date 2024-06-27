import asyncdispatch
import ../../../../../src/basolato/middleware


proc checkCsrfToken*(c:Context, p:Params):Future[Response] {.async.} =
  try:
    checkCsrfTokenForMpaHelper(c, p).await
    return next()
  except:
    # Define your own error handling logic here
    # return errorRedirect("/signin")
    return render(Http403, getCurrentExceptionMsg())


proc sessionFromCookie*(c:Context, p:Params):Future[Response] {.async.} =
  try:
    let cookies = sessionFromCookieHelper(c, p).await
    return next().setCookie(cookies)
  except:
    # Define your own error handling logic here
    let cookies = createNewSessionHelper(c).await
    return next().setCookie(cookies)
    # return errorRedirect("/signin").setCookie(cookies)
