effect module Hapi where { subscription = HapiSub } exposing (..)

import Dict exposing (Dict)
import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode
import Error exposing (Error)

import Hapi.Internals.Helpers as H
import Hapi.Internals.Replier as Replier
import Hapi.Internals.Handler as Handler

import Hapi.Http.Request as Request
import Hapi.Http.Response as Response

import Hapi.Route as Route
import Hapi.Route.Config as RouteConfig

import Hapi.Server as Server
import Hapi.Connection exposing (Connection)
import Hapi.Plugins.Plugin as Plugin

import Hapi.Native


-- -----------------------------------------------------------------------------
-- ALIASES
-- -----------------------------------------------------------------------------

type alias Replier = Replier.Replier
type alias Server = Server.Server
type alias Request = Request.Request
type alias Response = Response.Response
type alias Plugin = Plugin.Plugin
type alias Route = Route.Route
type alias RouteConfig = RouteConfig.Config

withPlugins: List Plugin -> Server -> Task Error Server
withPlugins = Native.Hapi.withPlugins

withRoute: Route -> Server -> Server
withRoute = Route.withRoute

withConnection: Connection -> Server -> Server
withConnection = Hapi.Connection.withConnection

defaultHandler: Handler.Handler
defaultHandler = Handler.init

defaultRouteConfig: RouteConfig
defaultRouteConfig = RouteConfig.init


type alias CreateConfig =
  { settings: Dict String String
  }

encodeCreateConfig: CreateConfig -> Encode.Value
encodeCreateConfig config =
  [ Just ("settings", H.encodeDict Encode.string config.settings)
  ]
  |> List.filterMap identity
  |> Encode.object


create: CreateConfig -> Task Error Server
create config =
  Native.Hapi.create (encodeCreateConfig config)
  |> Task.mapError Error.parse

start: Server -> Task Error Server
start server =
  Native.Hapi.start server
  |> Task.mapError Error.parse

stop: Server -> Task Error ()
stop server =
  Native.Hapi.stop server
  |> Task.mapError Error.parse

reply: Replier -> Response -> Task Error ()
reply replier response =
  Native.Hapi.reply replier (Response.encode response)
  |> Task.mapError Error.parse


-- -----------------------------------------------------------------------------
-- SUB
-- -----------------------------------------------------------------------------

type Msg
  = Requested Replier Request

type HapiSub msg
  = Listen (Msg -> msg)

listen: (Msg -> msg) -> Sub msg
listen =
  subscription << Listen

subMap : (a -> b) -> HapiSub a -> HapiSub b
subMap f sub =
  case sub of
    Listen tagger -> Listen (tagger >> f)


-- -----------------------------------------------------------------------------
-- STATE
-- -----------------------------------------------------------------------------

type alias State msg =
  { initialized: Bool
  , subs: List (HapiSub msg)
  }

init : Task Never (State msg)
init =
  Task.succeed { initialized = False, subs = [] }


-- -----------------------------------------------------------------------------
-- EFFECTS
-- -----------------------------------------------------------------------------

onEffects
  : Platform.Router msg SelfMsg
  -> List (HapiSub msg)
  -> State msg
  -> Task Never (State msg)
onEffects router subs state =
  (
    if state.initialized
    then Task.succeed state
    else
      Native.Hapi.init
        { sendToSelf = Platform.sendToSelf router
        , messages = { onRequest = OnRequest }
        }
      |> Task.map (\_ -> { state | initialized = True })
  )
  |> Task.map (\s -> { s | subs = subs })


-- -----------------------------------------------------------------------------
-- INTERNALS
-- -----------------------------------------------------------------------------

type SelfMsg
  = OnRequest Replier Encode.Value

msgToApp: Platform.Router msg SelfMsg -> State msg -> Msg -> Task Never (State msg)
msgToApp router state msg =
  state.subs
  |> List.map (\(Listen tagger) ->
    Platform.sendToApp router (tagger msg)
  )
  |> Task.sequence
  |> Task.map (\_ -> state)

onSelfMsg : Platform.Router msg SelfMsg -> SelfMsg -> State msg -> Task Never (State msg)
onSelfMsg router selfMsg state =
  case selfMsg of
    OnRequest replier jsRequest ->
      case Decode.decodeValue Request.decoder jsRequest of
        Ok request -> msgToApp router state (Requested replier request)

        Err error ->
          let
            a = Debug.log "Failed to parse request" error
          in
            Task.succeed state

noWarnings: String
noWarnings = Hapi.Native.noWarnings
