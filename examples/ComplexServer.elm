module ComplexServer exposing (..)

import Dict exposing (Dict)
import Task exposing (Task)

import Node.Path as Path

import Hapi exposing (Server, Request, Response, Replier)
import Hapi.Route as Route exposing (Route)
import Hapi.Connection as Connection
import Hapi.Http.Response as Response

import Hapi.Plugins.Inert as Inert

type alias Model = {}

type Msg
  = HapiMsg Hapi.Msg
  | Plugged (Result String Server)
  | Respond (Result (Replier, String) (Replier, Response))

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
          in
            model ! [ Task.attempt Plugged <| Hapi.withPlugins plugins server ]


      Hapi.Started res -> case res of
        Ok server ->
          let
            a = Debug.log "Server" ("started at " ++ host ++ ":" ++ port_)
          in
            model ! []

        Err error ->
          let
            a = Debug.log "Failed to start server" error
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
          response = handleRequest replier request
        in
          model ! [ Task.attempt Respond response ]


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
    Plugged result -> case result of
      Ok server ->
        let
          a = Debug.log "Server" "plugins registered"

          myServer =
            server
            -- Setup host and port for our server
            |> Hapi.withConnection (Connection.basic host port_)
            -- Add a route to serve all assets
            |> Hapi.withRoute assetsRoute
            -- Add a route to catch all requests
            |> Hapi.withRoute catchAllRoute
        in
          model ! [ Hapi.start myServer ]

      Err error ->
        let
          a = Debug.log "Failed to register plugins" error
        in
          model ! []


    Respond result -> case result of
      Ok (replier, response) ->
        model ! [ Hapi.reply replier response ]

      Err (replier, error) ->
        let
          response =
            Response.internalServerError
            |> Response.withBody error
        in
          model ! [ Hapi.reply replier response ]

subscriptions: Model -> Sub Msg
subscriptions model =
  Hapi.listen HapiMsg


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
