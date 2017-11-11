module ComplexServer exposing (..)

import Dict exposing (Dict)
import Task exposing (Task)
import Time exposing (Time)
import Error exposing (Error)

import Node.Path as Path

import Hapi exposing (Server, Request, Response, Replier)
import Hapi.Server exposing (Info, Load)
import Hapi.Route as Route exposing (Route)
import Hapi.Connection as Connection
import Hapi.Http.Response as Response

import Hapi.Plugins.Inert as Inert

type alias Model =
  { server: Maybe Server }

type Msg
  = HapiMsg Hapi.Msg
  | Started (Result Error Server)
  | Respond (Result (Replier, String) (Replier, Response))
  | Responded (Result Error ())
  | Tick Time
  | Print (Result String (Load, List Info))

main: Program Never Model Msg
main =
  Platform.program
    { init = init
    , update = update
    , subscriptions = subscriptions
    }

init: (Model, Cmd Msg)
init =
  { server = Nothing } ! [ Task.attempt Started initServer ]

initServer: Task Error Server
initServer =
  Hapi.create { settings = Dict.empty }
  |> Task.andThen (Hapi.withPlugins plugins)
  |> Task.map (\server ->
    server
    -- Setup host and port for our server
    |> Hapi.withConnection (Connection.basic host port_)
    -- Add a route to serve all assets
    |> Hapi.withRoute assetsRoute
    -- Add a route to catch all requests
    |> Hapi.withRoute catchAllRoute
  )
  |> Task.andThen Hapi.start


update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    -- Hapi stuff
    HapiMsg (Hapi.Requested replier request) ->
      let
        a = Debug.log "Received request" ((toString request.method) ++ " " ++ request.path)

        -- This is where you should plug all your logic as a "Task err Response"
        -- -> routing
        -- -> authentication
        -- -> body parsing & validation
        -- -> database queries
        -- -> response creation
        response = handleRequest replier request
      in
        model ! [ Task.attempt Respond response ]

    -- You own stuff
    Started result -> case result of
      Ok server ->
        let
          a = Debug.log "Server" ("started at " ++ host ++ ":" ++ port_)
        in
          { model | server = Just server } ! []

      Err error ->
        let
          a = Debug.log "Failed to start server" error
        in
          model ! []

    Respond result ->
      let
        (replier, response) = case result of
          Ok tuple ->
            tuple
          Err (replier, error) ->
            ( replier
            , Response.internalServerError |> Response.withBody error
            )
      in
        model ! [ Task.attempt Responded (Hapi.reply replier response) ]

    Responded result -> case result of
      Ok _ -> model ! []
      Err error ->
        let
          a = Debug.log "Failed to respond" error
        in
          model ! []

    Tick _ -> case model.server of
      Nothing -> model ! []
      Just server ->
        let
          task =
            Hapi.Server.getLoad server
            |> Task.andThen (\load ->
              Hapi.Server.getInfos server
              |> Task.map (\infos -> (load, infos))
            )
        in
          model ! [ Task.attempt Print task ]

    -- Every 5sec, we are printing some infos about the server current status
    Print result ->
      let
        z = case result of
          Err err ->
            Debug.log "Failed to get status" err
          Ok (load, infos) ->
            let
              a = Debug.log "Infos" infos
              b = Debug.log "Load" load
              c = Debug.log "-----------------------------------------------" ""
            in
              ""
      in
        model ! []

subscriptions: Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Hapi.listen HapiMsg
    , Time.every (5 * Time.second) Tick
    ]


-- -----------------------------------------------------------------------------
-- Server configuration

examplesPath: String
examplesPath = Path.resolve2 "." "examples"

host: String
host = "localhost"

port_: String
port_ = "8000"

assetsRoute: Route
assetsRoute =
  let
    defaultDirectoryConfig = Inert.directoryConfigFromPath "./assets"
    directoryConfig =
      { defaultDirectoryConfig
      | redirectToSlash = Just True
      , listing = Just True
      }

    defaultRouteConfig = Hapi.defaultRouteConfig
    routeConfig =
      { defaultRouteConfig
      | files = Just { relativeTo = examplesPath }
      }
  in
    { path = "/assets/{param*}"
    , method = Route.All
    , handler = Inert.directoryHandler directoryConfig
    , vhost = Nothing
    , config = Just routeConfig
    }

catchAllRoute: Route
catchAllRoute =
  { path = "/{url*}"
  , method = Route.All
  , handler = Hapi.defaultHandler
  , vhost = Nothing
  , config = Nothing
  }

plugins: List Hapi.Plugin
plugins =
  [ Inert.plugin Inert.defaultOptions
  ]

-- -----------------------------------------------------------------------------
-- All your magic and bizness logic

handleRequest: Replier -> Request -> Task (Replier, String) (Replier, Response)
handleRequest replier request =
  if String.startsWith "/favicon" request.path
  then
    Inert.fileConfigFromPath (examplesPath ++ "/assets/images/elm_logo_monochrome.svg")
    |> Inert.replyFile replier
    |> Task.succeed
  else
    Response.ok
    |> Response.withBody (requestToString request)
    |> Response.withHeader "Content-Type" "text/html; charset=utf-8"
    |> (\response -> (replier, response))
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
