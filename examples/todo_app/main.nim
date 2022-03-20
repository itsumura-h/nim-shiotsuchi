# framework
import ../../src/basolato
# controller
import app/http/controllers/welcome_controller
import app/http/controllers/todo_controller
import app/http/controllers/sign/signin_controller
import app/http/controllers/sign/signup_controller
# middleware
import app/http/middlewares/auth_middleware
import app/http/middlewares/set_headers_middleware


let ROUTES = @[
  Route.group("", @[
    Route.get("/", todo_controller.redirectTodo), # redirect to /todo

    Route.group("", @[
      Route.get("/signin", signin_controller.index),
      Route.post("/signin", signin_controller.store),
      Route.get("/signout", signin_controller.delete),
      Route.get("/signup", signup_controller.index),
      Route.post("/signup", signup_controller.store),
    ])
    .middleware(auth_middleware.loginSkip),

    Route.group("/todo", @[
      Route.get("", todo_controller.index),
      Route.get("/create", todo_controller.create),
      Route.post("/create", todo_controller.store),
      Route.post("/change-sort", todo_controller.changeSort),
    ])
    .middleware(auth_middleware.mustBeLoggedIn),

    Route.group("/api", @[
      Route.get("/index", welcome_controller.indexApi),
    ])
    .middleware(set_headers_middleware.setCorsHeadersMiddleware),
  ])
  .middleware(set_headers_middleware.setSecureHeadersMiddlware)
  .middleware(auth_middleware.checkCsrfTokenMiddleware),
]

serve(ROUTES)
