module SimpleServer exposing (..)

import Dict exposing (Dict)
import Task exposing (Task)

import Hapi exposing (Request, Response, Replier)
import Hapi.Route as Route exposing (Route)
import Hapi.Connection as Connection
import Hapi.Http.Response as Response

type alias Model = {}

type Msg
  = HapiMsg Hapi.Msg
  | Response Replier (Result String Response)

main: Program Never Model Msg
main =
  Platform.program
    { init = init
    , update = update
    , subscriptions = subscriptions
    }

init: (Model, Cmd Msg)
init =
  {} ! [ Hapi.create { settings = Dict.empty } ]

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    -- Hapi stuff
    HapiMsg hapiMsg -> case hapiMsg of
      Hapi.Created res -> case res of
        Err error ->
          let
            a = Debug.log "Failed to create server" error
          in
            model ! []

        Ok server ->
          let
            a = Debug.log "Server" "created"

            myServer =
              server
              -- Setup host and port for our server
              |> Hapi.withConnection (Connection.basic host port_)
              -- Add a route to catch all requests
              |> Hapi.withRoute route
          in
            model ! [ Hapi.start myServer ]

      Hapi.Started res -> case res of
        Ok server ->
          let
            a = Debug.log "Server" ("started at " ++ host ++ ":" ++ port_)
          in
            model ! []

        Err error ->
          let
            a = Debug.log "Failed to start server:" error
          in
            model ! []

      Hapi.Requested replier request ->
        let
          a = Debug.log "Received request" ((toString request.method) ++ " " ++ request.path)

          -- This is where you should plug all your logic as a "Task err Response"
          -- -> routing
          -- -> authentication
          -- -> body parsing & validation
          -- -> database queries
          -- -> response creation
          response = handleRequest request
        in
          model ! [ Task.attempt (Response replier) response ]

      Hapi.Stopped res -> case res of
        Ok server ->
          let
            a = Debug.log "Server" "stopped"
          in
            model ! []

        Err error ->
          let
            a = Debug.log "Failed to stop server" error
          in
            model ! []

    -- You own stuff
    Response replier result -> case result of
      Ok response ->
        model ! [ Hapi.reply replier response ]

      Err error ->
        let
          response =
            Response.internalServerError
            |> Response.withBody error
        in
          model ! [ Hapi.reply replier response ]

subscriptions: Model -> Sub Msg
subscriptions model =
  Hapi.listen HapiMsg

host: String
host = "localhost"

port_: String
port_ = "8080"

route: Route
route =
  { path = "/{url*}"
  , method = Route.All
  , vhost = Nothing
  , config = Nothing
  }

handleRequest: Request -> Task String Response
handleRequest request =
  Response.ok
  |> Response.withBody (requestToString request)
  |> Response.withHeader "Content-Type" "text/html; charset=utf-8"
  |> Task.succeed

requestToString: Request -> String
requestToString request =
  """
  <html>
    <body>
      <dl>
        <dt>Method</dd>
        <dd>""" ++ (toString request.method) ++ """</dd>
        <dt>Path</dt>
        <dd>""" ++ request.path ++ """</dd>
        <dt>Path params</dt>
        <dd>""" ++ (dictToString request.params) ++ """</dd>
        <dt>Query</dt>
        <dd>""" ++ (dictToString request.query) ++ """</dd>
        <dt>Headers</dt>
        <dd>""" ++ (dictToString request.headers) ++ """</dd>
        <dt>Body</dt>
        <dd>""" ++ (toString request.body) ++ """</dd>
      </dl>
    </body>
  </html>
  """

dictToString: Dict String String -> String
dictToString dict =
  if Dict.isEmpty dict
  then "Nothing"
  else
    """
    <ul style="padding:0"><li>
    """
    ++ (dict |> Dict.toList |> List.map (\(k,v) -> "<strong>"++k++":</strong> " ++ v) |> String.join "</li><li>") ++
    """
    </li></ul>
    """

-- sessionState: State
-- sessionState =
--   { ttl = Just 1000
--   , isSecure = True
--   , isHttpOnly = True
--   , isSameSite = Nothing
--   , path = "/"
--   , domain = Just "localhost"
--   , encoding = Just Hapi.State.Iron
--   , password = Just "your-super-long-and-secure-password"
--   , ignoreErrors = True
--   , clearInvalid = False
--   , strictHeader = True
--   }
